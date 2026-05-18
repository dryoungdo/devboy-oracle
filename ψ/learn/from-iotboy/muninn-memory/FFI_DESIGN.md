# Muninn Memory — FFI Design Sketch (Rust)

**Trigger**: P'Nat 2026-05-11 — "FFI เอาเรื่อง ขอดูโค้ดหน่อยดิ แนวคิด"
**Goal**: show concrete FFI surface so fleet can call Rust core from Python (mempalace migration), C/C++ (embedded ESP32), and WASM (browser dashboards).

---

## Crate layout (cargo workspace)

```
muninn-memory/
├── crates/
│   ├── muninn-core/        # pure Rust: engram, Hebbian, ACT-R, Bayesian (no_std friendly subset)
│   ├── muninn-store/       # Pebble/sled/redb storage adapters
│   ├── muninn-mcp/         # MCP server (stdio + SSE + HTTP)
│   ├── muninn-py/          # PyO3 bindings → muninn_memory wheel
│   ├── muninn-c/           # cbindgen → libmuninn.so + muninn.h
│   ├── muninn-wasm/        # wasm-bindgen → npm package
│   └── muninn-embedded/    # no_std + alloc, FRAM/LittleFS, ESP32 target
├── examples/
│   ├── esp32-watchtower.rs
│   ├── python-replace-chromadb.py
│   └── browser-engram-inspector.ts
└── Cargo.toml
```

`muninn-core` is the keystone — `no_std + alloc` so the same engram + cognitive math runs on ESP32 *and* server.

---

## 1. Core engram type (shared)

```rust
// crates/muninn-core/src/engram.rs
#![cfg_attr(not(feature = "std"), no_std)]
extern crate alloc;
use alloc::{string::String, vec::Vec};

#[derive(Clone, Debug)]
#[repr(C)]   // stable layout for C FFI
pub struct Engram {
    pub id: [u8; 16],          // ULID
    pub confidence: f32,
    pub stability: f32,
    pub access_count: u32,
    pub last_access_ns: u64,   // epoch nanoseconds
    pub created_at_ns: u64,
    pub state: LifecycleState,
    // variable-length fields stored separately on disk;
    // FFI surface only exposes the fixed metadata block
}

#[repr(u8)]
#[derive(Copy, Clone, Debug)]
pub enum LifecycleState {
    Planning = 0, Active = 1, Paused = 2, Blocked = 3,
    Completed = 4, Cancelled = 5, Archived = 6, SoftDeleted = 7,
}

pub fn hebbian_update(w: f32, eta: f32, n: u32) -> f32 {
    let factor = (1.0 + eta).powi(n as i32);
    (w * factor).min(1.0)
}

pub fn actr_activation(n_accesses: u32, age_days: f32) -> f32 {
    let n = n_accesses as f32;
    let age = age_days.max(0.1);
    let b = (n + 1.0).ln() - 0.5 * (age / (n + 1.0)).ln();
    softplus(b)
}

fn softplus(x: f32) -> f32 {
    (1.0 + x.exp()).ln()
}
```

---

## 2. Python via PyO3 (mempalace drop-in path)

```rust
// crates/muninn-py/src/lib.rs
use pyo3::prelude::*;
use muninn_core::{Engram, hebbian_update, actr_activation};

#[pyclass(name = "Engram")]
struct PyEngram { inner: Engram }

#[pyclass(name = "Store")]
struct PyStore { inner: muninn_store::Store }

#[pymethods]
impl PyStore {
    #[new]
    fn new(path: &str) -> PyResult<Self> {
        Ok(Self { inner: muninn_store::Store::open(path)? })
    }

    fn remember(&mut self, concept: &str, content: &str, tags: Vec<String>) -> PyResult<String> {
        let id = self.inner.remember(concept, content, &tags)?;
        Ok(ulid_to_string(id))
    }

    fn recall(&self, query: &str, top_k: usize) -> PyResult<Vec<(String, f32, String)>> {
        self.inner.recall(query, top_k)
            .map(|hits| hits.into_iter()
                .map(|h| (ulid_to_string(h.id), h.score, h.content))
                .collect())
            .map_err(Into::into)
    }
}

#[pymodule]
fn muninn_memory(_py: Python, m: &Bound<PyModule>) -> PyResult<()> {
    m.add_class::<PyEngram>()?;
    m.add_class::<PyStore>()?;
    Ok(())
}
```

Python side (mempalace drop-in):
```python
import muninn_memory as mm
store = mm.Store("./muninn.db")
eid = store.remember("ESP32 ADC noise", "spike on GPIO34 at 3.3V boundary", ["esp32", "adc"])
hits = store.recall("ADC drift", top_k=5)
for id, score, content in hits:
    print(f"{score:.3f}  {content}")
```

Build with `maturin develop` → `pip install muninn-memory`.

---

## 3. C/C++ ABI for embedded (ESP32 / Pi sidecar)

```rust
// crates/muninn-c/src/lib.rs
use muninn_core::*;
use core::ffi::{c_char, c_int};
use core::slice;

#[repr(C)]
pub struct MuninnHandle { _opaque: [u8; 0] }

#[no_mangle]
pub extern "C" fn muninn_open(path: *const c_char) -> *mut MuninnHandle {
    let path_str = unsafe { core::ffi::CStr::from_ptr(path).to_str().unwrap_or("") };
    match muninn_store::Store::open(path_str) {
        Ok(s) => Box::into_raw(Box::new(s)) as *mut MuninnHandle,
        Err(_) => core::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn muninn_remember(
    h: *mut MuninnHandle,
    concept_ptr: *const u8, concept_len: usize,
    content_ptr: *const u8, content_len: usize,
    out_id: *mut u8,   // [u8; 16]
) -> c_int {
    if h.is_null() || out_id.is_null() { return -1; }
    let store = unsafe { &mut *(h as *mut muninn_store::Store) };
    let concept = unsafe { slice::from_raw_parts(concept_ptr, concept_len) };
    let content = unsafe { slice::from_raw_parts(content_ptr, content_len) };
    match store.remember_bytes(concept, content) {
        Ok(id) => {
            unsafe { core::ptr::copy_nonoverlapping(id.as_ptr(), out_id, 16); }
            0
        }
        Err(_) => -2,
    }
}

#[no_mangle]
pub extern "C" fn muninn_close(h: *mut MuninnHandle) {
    if !h.is_null() { unsafe { drop(Box::from_raw(h as *mut muninn_store::Store)) } }
}
```

`cbindgen --crate muninn-c --output muninn.h` produces:
```c
typedef struct MuninnHandle MuninnHandle;
MuninnHandle* muninn_open(const char* path);
int muninn_remember(MuninnHandle* h,
                    const uint8_t* concept_ptr, size_t concept_len,
                    const uint8_t* content_ptr, size_t content_len,
                    uint8_t out_id[16]);
void muninn_close(MuninnHandle* h);
```

Arduino / ESP-IDF wrapper:
```cpp
extern "C" {
  #include "muninn.h"
}

class Watchtower {
public:
  Watchtower(const char* path) : h_(muninn_open(path)) {}
  ~Watchtower() { muninn_close(h_); }

  bool remember(const String& concept, const String& content) {
    uint8_t id[16];
    return muninn_remember(h_,
        (const uint8_t*)concept.c_str(), concept.length(),
        (const uint8_t*)content.c_str(), content.length(),
        id) == 0;
  }
private:
  MuninnHandle* h_;
};
```

---

## 4. WASM for browser (FORGEBOY dashboard)

```rust
// crates/muninn-wasm/src/lib.rs
use wasm_bindgen::prelude::*;
use muninn_core::actr_activation;

#[wasm_bindgen]
pub fn visualize_decay(n: u32, max_age_days: f32, steps: u32) -> Vec<f32> {
    (0..steps)
        .map(|i| {
            let age = (i as f32 / steps as f32) * max_age_days;
            actr_activation(n, age)
        })
        .collect()
}
```

Then `wasm-pack build --target web --release` → npm publish. FORGEBOY can plot decay curves in-browser without server round-trips.

---

## 5. Embedded ESP32 (no_std + alloc)

```rust
// crates/muninn-embedded/src/lib.rs
#![no_std]
extern crate alloc;

use embedded_storage::ReadStorage;
use muninn_core::Engram;

// FRAM-backed engram store — fixed 1024-slot ring buffer
pub struct FramStore<F: ReadStorage> {
    fram: F,
    head: usize,
}

impl<F: ReadStorage> FramStore<F> {
    pub const SLOT_BYTES: usize = 128;
    pub const SLOTS: usize = 1024;

    pub fn push(&mut self, e: &Engram) -> Result<(), F::Error> {
        // serialize fixed metadata into 128B slot
        // bump head, wrap on overflow (oldest engram archived to flash)
        unimplemented!()
    }

    pub fn iter(&self) -> impl Iterator<Item = Engram> + '_ {
        core::iter::empty()  // sketch
    }
}
```

Pair with `embassy` async runtime for deep-sleep-friendly decay scheduling — engrams decay on wake, not continuous.

---

## Why this matters

- **Single source of truth** — Hebbian + ACT-R formulas implemented ONCE in `muninn-core` (no_std). Every binding wraps the same math.
- **No Python lock-in** — mempalace users migrate gradually (Python wrapper → native Rust later).
- **Edge sovereignty** — ESP32 device has its OWN micro-engram store, syncs upstream when WiFi/LoRa available.
- **Patent dodge** — clean-room implementation of public formulas; cite Anderson 1993 + Hebb 1949 as prior art; license MIT.

## What I'd build first (ordered)

1. `muninn-core` (engram + Hebbian + ACT-R + Bayesian) — 1 week, testable in isolation
2. `muninn-store` (Pebble equivalent via `sled` or `redb`) — 2 weeks
3. `muninn-py` (PyO3 + maturin wheel) — 3 days, unblocks mempalace fleet adoption test
4. `muninn-c` (cbindgen) — 3 days
5. `muninn-mcp` (MCP server, stdio + SSE) — 1 week
6. `muninn-embedded` (no_std FRAM ring buffer) — 2 weeks (my scope)
7. `muninn-wasm` — 3 days, FORGEBOY ready

Total v0.1: **6-8 weeks for 1 senior + 2 mid Rust devs**.

# Elysia Architecture Deep Dive

**Version**: 1.4.28 | **Date**: 2026-05-09 | **Framework**: Bun-native TypeScript Web Framework

---

## Table of Contents
1. [Top-Level Directory Map](#top-level-directory-map)
2. [Entry Points & Main Exports](#entry-points--main-exports)
3. [Core Modules](#core-modules)
4. [Request Flow & Handler Resolution](#request-flow--handler-resolution)
5. [TypeScript Type Inference (End-to-End)](#typescript-type-inference-end-to-end)
6. [Plugin System & Composition Architecture](#plugin-system--composition-architecture)
7. [Bun-Specific Implementation](#bun-specific-implementation)
8. [Adapters for Node / Cloudflare / Web Standard](#adapters-for-node--cloudflare--web-standard)
9. [Dependencies](#dependencies)
10. [Key Design Patterns](#key-design-patterns)

---

## Top-Level Directory Map

```
elysia/
├── src/                          # Main framework source code (39 TS files)
├── example/                       # Examples: basic, websocket, guard, schema, etc.
├── test/                          # Test suites (functionality, types, Node compat, Cloudflare)
├── dist/                          # Built output (esm, cjs, types)
├── .github/                       # CI/CD workflows
├── build.ts                       # Build entry point (tsup + tsc)
├── package.json                   # v1.4.28, exports 40+ subpaths
├── tsconfig.json                  # TypeScript config with strict settings
├── bun.lock                       # Bun lockfile
└── CHANGELOG.md                   # Detailed release history
```

---

## Entry Points & Main Exports

### Primary Entry: `src/index.ts` (8,366 lines)
- **Default Export**: `Elysia` class
  - Generic class with 7 type parameters (BasePath, Singleton, Definitions, Metadata, Routes, Ephemeral, Volatile)
  - Manages server lifecycle, route registration, handler composition, type inference

### Secondary Exports (package.json subpaths)
```
elysia              → dist/index.{js,mjs,d.ts}
elysia/ws           → WebSocket integration (bun-native)
elysia/sucrose      → Static analyzer for type inference
elysia/schema       → Schema validation & type mapping
elysia/compose      → Handler composition utilities
elysia/context      → Context types & utilities
elysia/error        → Error handling classes
elysia/adapter      → Multi-platform adapters (Bun, Web Standard, Cloudflare)
elysia/type-system  → TypeBox integration + Elysia extensions
elysia/trace        → Request tracing for debugging
```

### No `bin/` Directory
- Elysia is a library, not a CLI tool. Use `bun create elysia app` for scaffolding (external).

---

## Core Modules

### 1. **Main Class: `Elysia` (src/index.ts)**
**Size**: 8,366 lines | **Generic Parameters**: 7

**Internal State**:
- `singleton`: Decorator, store, derive, resolve (app-wide, shared)
- `definitions`: TypeBox schemas, error types, metadata
- `extender`: Macros, higher-order functions
- `validator`: 3-layer (global, scoped, local) schema validators
- `standaloneValidator`: Standard Schema support
- `routes`: InternalRoute array (type-erased, resolved at runtime)
- `telemetry`: Optional debug tracing

**Key Methods**:
- `use()`: Plugin composition (overloaded 8 times for flexibility)
- `get/post/put/patch/delete()`: Route handlers (return Eden types for type-safe client SDKs)
- `compile()`: Compiles routes to machine code (Bun.serve compatible)
- `listen()`: Starts server via adapter
- `guard()`, `macro()`, `derive()`, `resolve()`: Middleware composition
- `stop()`: Graceful shutdown

---

### 2. **Sucrose: Static Analyzer (src/sucrose.ts)**
**Size**: ~1,500 lines (2,804 with compose.ts)

**Purpose**: Infers which context properties a handler **actually uses**, enabling dead-code elimination and reduced bundle size.

**Core Concepts**:
- `Sucrose.Inference`: Boolean flags for (query, headers, body, cookie, set, server, route, url, path)
- `separateFunction()`: Parses arrow/async function signature & body
- `inferBodyReference()`: Uses AST-like parsing to detect property accesses
- `mergeInference()`: Combines inference from multiple handlers

**Usage**:
- Applied at route composition time
- Generates optimized `c.body`, `c.headers` access—**only what's needed**
- Reduces JIT code bloat in hot paths

**Example** (conceptual):
```ts
// Sucrose detects: body=true, query=true, others=false
.post("/", ({ body, query }) => body)

// Generates optimized handler:
// c.body = await request.json()
// c.query = parseQuery(...)
// // NO: c.headers, c.params, c.cookie initialization
```

---

### 3. **Schema Validation (src/schema.ts)**
**Size**: ~1,400 lines

**Integration**: Uses **@sinclair/typebox** (peer dependency)

**Key Components**:
- `ElysiaTypeCheck`: Wrapper around TypeBox's `TypeCompiler`
- `getSchemaValidator()`: Compiles TypeBox schema to JIT validator
- `getResponseSchemaValidator()`: Runtime response validation
- `getCookieValidator()`: Cookie parsing + validation
- `resolveSchema()`: Handles `StandardSchemaV1Like` (valibot, arktype, zod-compatible)
- `replaceSchema()`: Coercion for primitives (form data, query strings)

**Validation Layers**:
1. **Global**: Applied to all routes
2. **Scoped**: Plugin-level defaults
3. **Local**: Per-route overrides

**Standard Schema Support** (v26.4+):
- Allows Zod, Valibot, Arktype schemas via `~standard` protocol
- Auto-detection via `FastStandardSchemaV1Like` interface

---

### 4. **Type System (src/type-system/)**
**Files**: index.ts, types.ts, utils.ts, format.ts

**TypeBox Extensions** (Elysia-specific types):
- `t.File()`, `t.Files()`: File upload handling
- `t.Form()`: FormData parsing
- `t.ArrayBuffer()`: Binary data
- `t.UnionEnum()`: Union of enums
- `t.Date()`: ISO 8601 parsing with custom format
- `ElysiaTransformDecodeBuilder`: Decode transformations

**Format Support**:
- ISO 8601 dates with space handling
- Custom format registry for validation

---

### 5. **Router (implicit, spread across files)**
**No single router file**. Routing resolved via:
- `Memoirist` library: Route tree with memoization
- Path normalization: `getLoosePath()`, `encodePath()`
- Bun's native router (via BunAdapter) or fallback dynamic handler

**Route Matching**:
1. Static routes: Memoirist tree (O(1) lookup)
2. Dynamic routes: Regex path parameters (`:id`, `:name?`)
3. Wildcard routes: Greedy matching

**Bun Optimization**:
- Native `createNativeStaticHandler()`: Generates static route object
- Format: `{ GET: { '/path': handler, ... }, POST: { ... } }`
- Bun's internal router matches in ~nanoseconds

---

### 6. **Handler Composition (src/compose.ts)**
**Size**: 2,804 lines

**Pipeline Stages**:
1. **Pre-Handler**: Schema validation, cookies, guard checks
2. **Main Handler**: User route function
3. **After Handler**: Response transformation, headers, set cookies
4. **Error Handler**: Custom error handling per route

**Code Generation**:
- `composeHandler()`: Creates JIT handler function
- Inlines schema validators, hook calls, response mapping
- Uses Sucrose to eliminate unused context properties
- Output: Highly optimized function (can be 100+ lines per route)

**Example (generated)**:
```js
// Pseudocode of generated handler
async function handler(c) {
  // Sucrose-optimized context init
  c.body = await request.json()
  c.headers = {...}
  
  // Guard check
  if (!(guard_fn)) throw ...
  
  // Before handler
  let ctx = await beforeHandle?.(c)
  
  // Main handler
  const response = handler_fn(c)
  
  // After handler
  if (afterHandle) await afterHandle(c)
  
  // Response mapping
  return mapResponse(response, c.set)
}
```

---

### 7. **Dynamic Handler (src/dynamic-handle.ts)**
**Size**: 935 lines

**Purpose**: JIT handler for dynamic routes + error handling

**Features**:
- Runtime validation for unknown request shapes
- Cookie parsing, form data extraction
- Nested value setting (e.g., `body.user[0].name`)
- Dangerous key protection (`__proto__`, `constructor`, `prototype`)
- File upload handling via `ElysiaFile`

**Used When**:
- Route handlers are not pre-compiled
- Fallback for adapters without native static handlers
- Error routes

---

### 8. **WebSocket (src/ws/)**
**Files**: index.ts, types.ts, bun.ts

**Bun Native**:
- `ElysiaWS`: Wraps `Bun.server.websocket()`
- Events: open, message, drain, close, ping, pong
- Schema validation for message payloads
- Per-socket data storage (id, validator, custom data)

**Integration**:
- Registered via `.ws()` method on Elysia
- Shares same type system as HTTP routes
- Response auto-detection for `ws.upgrade()`

---

### 9. **Error Handling (src/error.ts)**
**Size**: ~550 lines

**Built-in Error Classes**:
- `InternalServerError`: 500
- `NotFoundError`: 404
- `ParseError`: 400 (invalid JSON)
- `ValidationError`: 422 (schema mismatch)
- `InvalidCookieSignature`: 401
- `InvalidFileType`: 400 (file validation)
- `ElysiaCustomStatusResponse`: Custom status (e.g., 418, 429)

**Features**:
- `mapValueError()`: Converts TypeBox validation errors → readable format
- Nested error details (path, value, expected)
- Custom `.handle()` override per route
- Global error handler fallback

---

### 10. **Cookies (src/cookies.ts)**
**Size**: ~500 lines

**Features**:
- `parseCookie()`: Parse Set-Cookie headers
- `serializeCookie()`: Serialize cookie options (maxAge, domain, secure, httpOnly, sameSite, etc.)
- Cookie signing with HMAC (requires secret)
- `CookieOptions`: Full RFC 6265 support

---

### 11. **Context (src/context.ts)**
**Type-Heavy File**: ~500 lines (mostly type definitions)

**Context<Route, Singleton>** structure:
- **Input**: `body`, `query`, `params`, `headers`, `cookie`
- **State**: `store`, `decorator`, `derive`, `resolve`
- **Output**: `set` (headers, cookies, status, redirect)
- **Server**: `server` (Bun.serve handle)
- **Request**: `request` (native Request)

**Type Inference Chain**:
- Merged from route schema + singleton
- Supports route-local overrides (ephemeral, volatile)

---

## Request Flow & Handler Resolution

### High-Level Flow

```
Request (HTTP/WebSocket)
    ↓
[Adapter Layer] → Map to native request (Bun, Web Standard, Cloudflare)
    ↓
[Router] → Memoirist tree lookup or dynamic matching
    ↓
[Composed Handler] → Schema validation → Guard check → Main handler
    ↓
[Response Mapping] → mapResponse() → set cookies → return Response
    ↓
[Adapter Response] → Serialize for platform (Bun, Cloudflare, etc.)
```

### Detailed Steps (for a typed POST route)

1. **Request Arrives**: e.g., `POST /users` with `{"name":"Alice"}`

2. **Route Matching** (BunAdapter):
   ```ts
   // Bun's native router (from createNativeStaticHandler)
   routes.POST['/users']  // → handler function reference
   ```

3. **Composed Handler Invoked**:
   ```ts
   // Pre-generated at compile time
   const handler = composeHandler({
     path: '/users',
     schema: { body: t.Object({name: t.String()}) },
     hooks: { beforeHandle, afterHandle },
     fn: userCreateHandler
   })
   ```

4. **Context Assembly**:
   - `c.body = await request.json()` (via Sucrose inference)
   - `c.set = {}` (response object)

5. **Validation**:
   ```ts
   const validator = getSchemaValidator(schema)
   const errors = validator.check(c.body)
   if (errors) throw new ValidationError(...)
   ```

6. **Guard Execution** (if present):
   ```ts
   if (guard && !guard(c)) throw new ValidationError(...)
   ```

7. **Before-Handle Hook**:
   ```ts
   c = await beforeHandle(c)  // Can modify context
   ```

8. **Main Handler**:
   ```ts
   const response = userCreateHandler(c)  // User code
   ```

9. **After-Handle Hook**:
   ```ts
   await afterHandle(c)  // Side effects, logging
   ```

10. **Response Mapping**:
    ```ts
    mapResponse(response, c.set)
    // → Response instance with headers, cookies, status
    ```

11. **Return to Adapter**:
    - BunAdapter: Return Response directly
    - WebStandardAdapter: Wrap in Response if needed
    - Cloudflare: Map to CF Response format

---

## TypeScript Type Inference (End-to-End)

### The Challenge
Elysia achieves **full end-to-end type safety** where:
- Route definitions infer parameter types → request validation
- Response types infer return type → client SDK generation (Eden)
- No manual type annotations needed beyond schema definition

### Core Type Mechanics

#### 1. **Schema → Route Inference**
```ts
app.post('/users', ({ body }) => body, {
  body: t.Object({ name: t.String() })
})

// Infers:
// - body: { name: string }
// - Validation applied automatically
// - Response type: same as return type
```

#### 2. **Generic Type Parameters** (Elysia class)

```ts
class Elysia<
  BasePath extends string = '',
  Singleton extends SingletonBase = {...},
  Definitions extends DefinitionBase = {...},
  Metadata extends MetadataBase = {...},
  Routes extends RouteBase = {},
  Ephemeral extends EphemeralType = {...},
  Volatile extends EphemeralType = {...}
>
```

**Each parameter tracks**:
- `BasePath`: Route prefix (`/api`)
- `Singleton.decorator`: App-wide context extensions (e.g., `db`)
- `Definitions.typebox`: Named schemas for reuse
- `Metadata.schema`: Route-specific schemas (merged)
- `Routes`: Union of all route signatures (for Eden)
- `Ephemeral`: Scoped (plugin-level) context
- `Volatile`: Local (route-level) context

#### 3. **Conditional Type Merging**
- **`.use(plugin)`**: Merges plugin's types into parent
- **`.derive()`**: Adds computed properties (with type preservation)
- **`.resolve()`**: Async context resolution (lazy evaluation)
- **`.macro()`**: Custom type-safe utilities

#### 4. **Eden Client SDK**
```ts
// From route definitions, Elysia generates client types
// Example (generated):
type Routes = {
  POST: {
    '/users': {
      body: { name: string }
      response: { id: number, name: string }
    }
  }
}

// eden.post('/users', { body: { name: 'Alice' } })
// → TypeScript knows response shape
```

### Sucrose Integration
- **Static Analysis**: Infers which context properties **actually accessed**
- **Reduces Inference Cost**: Only validates used fields
- **Example**: If handler doesn't use `query`, query parser skipped

---

## Plugin System & Composition Architecture

### Design: **Horizontal Type Merging**

Elysia plugins are composable via `.use()`, not inheritance.

### Plugin Structure

```ts
// Simple plugin
const logger = new Elysia({ name: 'logger' })
  .derive({ as: 'global' }, () => ({
    log: console.log
  }))

app.use(logger)
```

### Plugin Types

1. **Singleton Extension**
   ```ts
   .decorate({ db: database })  // App-wide decorator
   .store({ counter: 0 })        // Mutable store
   .derive({ session: () => {...} })  // Computed per-request
   .resolve({ auth: async () => {...} })  // Lazy async
   ```

2. **Metadata Injection**
   ```ts
   .model('User', t.Object({...}))
   .error('ValidationFailed', ValidationError)
   .setMetadata({ ...custom metadata })
   ```

3. **Macro Definition**
   ```ts
   .macro({ 
     requireAuth: (fn) => fn
       .guard(({ auth }) => auth)
   })
   ```

4. **Route Hooks**
   ```ts
   .onBeforeHandle((c) => {...})  // Global hook
   .onAfterHandle((c) => {...})
   .onError((error, c) => {...})
   ```

### Composition via `.use()`

```ts
const api = new Elysia({ prefix: '/api' })
  .use(authPlugin)
  .use(corsPlugin)
  .get('/posts', postHandler)

const app = new Elysia()
  .use(api)
  .listen(3000)

// Result: All types composed, merged singleton/definitions
// Routes available at /api/posts
```

### Type Merging Algorithm

1. **Non-overlapping keys**: Merged directly
2. **Overlapping keys**:
   - `decorator`: Intersection (all properties available)
   - `store`: Extended (new properties added)
   - `error`: Extended (new error types available)
3. **Routes**: Unioned into single Routes union type

### Deduplication

- Each plugin has a `name` (for internal deduplication)
- `.use(samePlugin)` → checks checksum, skips if duplicate
- Prevents circular dependency issues

---

## Bun-Specific Implementation

### Why Bun?

1. **Native Server**: `Bun.serve()` faster than Node.js
2. **WebSocket API**: Built-in, optimized
3. **Plugin System**: Leverages Bun's ecosystem
4. **TypeScript**: Bun runs TS natively (no build step needed)

### Bun Adapter (`src/adapter/bun/`)

#### Entry: `src/adapter/bun/index.ts`
- Implements `ElysiaAdapter` interface
- Uses `Bun.serve()` for HTTP
- Uses `websocket` handler for WS upgrades

#### Handler Optimization: `src/adapter/bun/handler-native.ts`
- **`createNativeStaticHandler()`**: Generates **static route object**
  ```ts
  const routes = {
    GET: {
      '/': staticHandler1,
      '/users/:id': staticHandler2
    },
    POST: {
      '/users': postHandler
    }
  }
  // Bun's router matches in nanoseconds (no regex overhead)
  ```

#### Bun-Specific Features
- **Response.json()**: Faster than `JSON.stringify()` wrapper
- **Native headers**: Direct manipulation (no string parsing in hot path)
- **Streaming**: `Bun.file()`, Response.stream()

### Adapter Type (`src/adapter/types.ts`)

```ts
interface ElysiaAdapter {
  name: string
  listen(app): (options, callback) => void
  stop?(app): Promise<void>
  
  handler: {
    mapResponse(response, set): Response
    mapEarlyResponse(response, set): Response | undefined
    mapCompactResponse(response, set): Response
    createStaticHandler(fn, config): Function
  }
  
  composeHandler: {
    mapResponseContext?: string  // e.g., 'c.request'
    preferWebstandardHeaders?: boolean
    headers?: string  // Code to initialize headers
    parser?: {
      json?(isOptional): string
      text?(): string
      urlencoded?(): string
    }
  }
}
```

---

## Adapters for Node / Cloudflare / Web Standard

### 1. **Web Standard Adapter** (`src/adapter/web-standard/`)
- **Target**: Node.js (with `node:http` → fetch bridge), Deno, other WinterCG runtimes
- **API**: Uses `fetch(Request): Promise<Response>`
- **Headers**: Prefers standard `Headers` object

### 2. **Cloudflare Workers Adapter** (`src/adapter/cloudflare-worker/`)
- **Target**: Cloudflare Workers (HTTP & Durable Objects)
- **API**: `fetch(Request): Promise<Response>`
- **Optimizations**: Stateless design (no long-lived server)
- **WS**: Supported via Durable Objects (different lifecycle)

### 3. **Bun Adapter** (default)
- **Target**: Bun runtime
- **API**: `Bun.serve()` native
- **WS**: Native `Bun.websocket()`
- **Features**: Fastest, most optimized

### Adapter Selection

```ts
const app = new Elysia({
  adapter: new WebStandardAdapter()  // or CloudflareWorkerAdapter, BunAdapter
})
```

---

## Dependencies

### Production Dependencies (4)
```json
{
  "cookie": "^1.1.1",              // RFC 6265 parsing & serialization
  "exact-mirror": "^0.2.7",        // Object introspection for type mapping
  "fast-decode-uri-component": "^1.0.1",  // Optimized URL decoding
  "memoirist": "^0.4.0"            // Route tree with memoization
}
```

### Peer Dependencies (5)
```json
{
  "@sinclair/typebox": ">= 0.34.0 < 1",    // Schema validation (required)
  "@types/bun": ">= 1.2.0",                 // Bun type definitions (optional)
  "file-type": ">= 20.0.0",                 // MIME detection (optional)
  "openapi-types": ">= 12.0.0",             // OpenAPI integration (optional)
  "typescript": ">= 5.0.0"                  // TS support (optional)
}
```

### Dev Dependencies (20+)
- **Testing**: Bun test, @types/bun
- **Type checking**: TypeScript, tsconfig
- **Linting**: ESLint + plugins
- **Building**: tsup, esbuild
- **Schema**: Zod, Valibot, Arktype (for testing standard schemas)
- **OpenAPI**: @elysiajs/openapi

### Minimal Footprint
- **No runtime dependencies on NodeJS APIs**
- **Tree-shakeable**: Unused adapters, features excluded
- **Bundle size**: ~50KB minified (core)

---

## Key Design Patterns

### 1. **Builder Pattern**
```ts
new Elysia()
  .get('/a', handler1)
  .get('/b', handler2)
  .listen(3000)
  
// Each method returns updated Elysia instance
```

### 2. **Generic Type Accumulation**
- Each `.use()`, `.get()`, `.post()` refines type parameters
- Enables **compile-time route validation** (no runtime overhead)

### 3. **Schema as Source of Truth**
- Single definition (TypeBox schema) → validation + documentation + client SDK
- No separate type annotations needed

### 4. **Adapter Pattern**
- Pluggable platform support (Bun, Web Standard, Cloudflare)
- Consistent API across environments

### 5. **Middleware via Hooks**
- `beforeHandle`: Pre-processing (validation, guards)
- `afterHandle`: Post-processing (logging, cleanup)
- `onError`: Error handling, recovery
- **Global + scoped + local** composition

### 6. **Lazy Compilation**
- Routes compiled **on first use** (JIT)
- `.compile()` explicitly triggers pre-compilation
- Reduces startup time for large apps

### 7. **Type Erasure at Runtime**
- Routes stored as `InternalRoute[]` (generic parameters dropped)
- Rebuilt via adapter at runtime
- Enables dynamic route registration

### 8. **Code Generation over Configuration**
- Handlers **generated functions** (not interpreter loops)
- Inline validation, hooks, response mapping
- Maximizes performance

---

## Summary Table

| Component | Files | Purpose | Key Tech |
|-----------|-------|---------|----------|
| **Main Class** | index.ts | Server lifecycle, route registration | TypeScript generics |
| **Sucrose** | sucrose.ts, compose.ts | Static analysis, code gen | AST-like parsing |
| **Schema** | schema.ts | Validation, type inference | TypeBox, Standard Schema |
| **Type System** | type-system/ | Custom validators, formats | TypeBox extensions |
| **Router** | (implicit) | Route matching | Memoirist + Bun native |
| **Handler Composition** | compose.ts | JIT function generation | Code template strings |
| **Dynamic Handler** | dynamic-handle.ts | Runtime validation | Form/cookie parsing |
| **WebSocket** | ws/ | Real-time bidirectional | Bun.websocket |
| **Error Handling** | error.ts | HTTP errors, type mapping | Custom classes |
| **Adapters** | adapter/ | Platform support | Bun, Web Standard, CF |
| **Context** | context.ts | Request/response types | Conditional type merging |

---

## Architectural Decisions

### Why No Single Router File?
- Routing is **adapter-specific** (Bun uses native, Web Standard uses dynamic)
- Keeps code close to where it's used
- Allows platform-specific optimizations

### Why Sucrose Exists
- Performance: Don't validate/initialize unused properties
- Bundle size: Dead-code elimination
- Developer experience: Implicit inference (no boilerplate)

### Why Code Generation?
- Speed: No interpreter overhead
- Type safety: Errors caught at compile time
- Optimization: Inline, no closures needed

### Why Plugin Composition?
- Flexibility: Mix and match features
- Type safety: Merging preserves types
- Reusability: Share across projects

---

## References

**Build Output**: `dist/` (ESM + CJS)  
**Configuration**: tsconfig.json, tsconfig.dts.json  
**Build Tool**: tsup (wraps esbuild)  
**Platform**: Bun 1.x+  
**License**: MIT  
**Repository**: github.com/elysiajs/elysia  

---

*End of Architecture Document*

# ESP32 Class — Code Snippets

Sketches, ESP-IDF projects, MicroPython scripts shared by P'Nat or written by Captain during class.

## Layout

```
code/
├── lectures/
│   └── lecture-NN/        # P'Nat's original sketches, unmodified
│       ├── source.txt     # Discord message ID + timestamp
│       └── *.ino, *.c, *.py
└── exercises/
    └── <slug>/            # Captain's hands-on attempts (incl. failed ones)
        ├── attempt-1/
        ├── attempt-2/
        └── notes.md
```

## Rules

- **Never edit P'Nat's sketches in place.** Copy to `exercises/` to modify.
- **Failed attempts stay.** Principle 1 — Nothing is Deleted. They are the soil tomorrow's working code grows from.
- **Compile environment matters.** Note in `notes.md`: PlatformIO env, ESP-IDF version, Arduino core version. Reproducibility is sacred (Standing Order #7).
- **Serial output is evidence.** Save captures from `serial-monitor` runs in `notes.md` with timestamps. "It worked" without serial output is not evidence.

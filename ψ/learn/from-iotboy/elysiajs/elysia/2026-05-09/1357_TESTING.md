# Elysia Testing Posture

## Overview
Elysia uses **Bun's native test framework** (`bun:test`) as its primary testing infrastructure. The project maintains comprehensive test coverage across functionality, type safety, and cross-runtime compatibility (Node.js, Cloudflare Workers).

---

## Test Framework: Bun Test

**Framework**: `bun:test` (built-in Bun testing framework)
**Primary Command**: `bun test`
**Test Files Pattern**: `test/**/*.test.ts`

### Available Test Scripts (from package.json)
```json
"test": "bun run test:functionality && bun run test:types && bun run test:node",
"test:functionality": "bun test && bun run test:imports",
"test:imports": "bun run test/type-system/import.ts",
"test:types": "tsc --project tsconfig.test.json",
"test:node": "npm install --prefix test/node/cjs && npm install --prefix test/node/esm/ && node test/node/cjs/index.js && node test/node/esm/index.js",
"test:cf": "npm install --prefix test/cloudflare && cd test/cloudflare && bun run cf-typegen && bun run test"
```

---

## Test Directory Structure

```
test/
├── core/              # Core routing and lifecycle tests (23+ test files)
├── adapter/           # Runtime adapter tests (bun, web-standard)
├── types/             # Type-level validation tests
│   ├── lifecycle/     # Lifecycle type tests (soundness, derive, resolve)
│   └── standard-schema/
├── schema/            # Schema validation tests
├── validator/         # Validator integration tests
├── plugins/           # Plugin system tests
├── lifecycle/         # Lifecycle hooks tests
├── path/              # Path routing tests
├── response/          # Response handling tests
├── ws/                # WebSocket tests
├── macro/             # Macro functionality tests
├── cloudflare/        # Cloudflare Workers adapter tests
├── node/              # Node.js compatibility tests (CJS/ESM)
├── extends/           # Extension tests
├── hoc/               # Higher-order component tests
├── aot/               # Ahead-of-Time compilation tests
├── production/        # Production build tests
├── units/             # Unit tests
├── tracer/            # Tracer functionality tests
├── sucrose/           # Sucrose plugin tests
├── standard-schema/   # Standard schema tests
├── cookie/            # Cookie handling tests
├── bun/               # Bun-specific tests
├── images/            # Test fixtures (image files for upload tests)
├── utils.ts           # Shared test utilities
└── type-system/       # Type system tests and imports
```

---

## How Routes Are Tested

**Pattern**: Routes are tested using `.handle(new Request(...))` without spinning up a Bun.serve server.

### Request Utility
Test utilities provide a `req()` helper function:

```typescript
export const req = (path: string, options?: RequestInit) =>
  new Request(`http://localhost${path}`, options)
```

This creates a Request object that's passed directly to the app's `.handle()` method.

### POST Request Helper
For POST requests with JSON/form bodies:

```typescript
export const post = (path: string, body?: string | Record<string, any>) =>
  typeof body === 'string'
    ? new Request(`http://localhost${path}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'text/plain',
          'Content-Length': String(Buffer.byteLength(body))
        },
        body
      })
    : new Request(`http://localhost${path}`, {
        method: 'POST',
        headers: body ? {
          'Content-Type': 'application/json',
          'Content-Length': String(Buffer.byteLength(JSON.stringify(body)))
        } : {},
        body: body ? JSON.stringify(body) : body
      })
```

### File Upload Helper
For multipart/form-data with actual files:

```typescript
export const upload = (
  path: string,
  fields: Record<string, MaybeArray<string>>
) => {
  const body = new FormData()
  let size = 0
  
  for (const [key, value] of Object.entries(fields)) {
    if (Array.isArray(value))
      value.forEach((value) => {
        const file = Bun.file(`./test/images/${value}`)
        size += file.size
        body.append(key, file)
      })
    else if (value.includes('.')) {
      const file = Bun.file(`./test/images/${value}`)
      size += file.size
      body.append(key, file)
    } else body.append(key, value)
  }
  
  return {
    request: new Request(`http://localhost${path}`, {
      method: 'POST',
      body
    }),
    size
  }
}
```

---

## Mocking Strategy

Elysia doesn't use external mocking libraries. Mocking is done through:
1. **In-memory Request objects** - Routes are tested with synchronous Request handling
2. **State injection** - Using `.state()` to inject test data
3. **Middleware chains** - Testing guards and hooks that modify context

No Sinon, Vitest mocks, or Jest mocking infrastructure detected.

---

## Type-Level Testing

Elysia has **first-class type-level testing** using `expect-type` library.

### Type Test Patterns
Files in `test/types/` use `expectTypeOf` from the `expect-type` library:

```typescript
import { expectTypeOf } from 'expect-type'

// Type equality check
{
  new Elysia().post(
    '/',
    ({ body }) => {
      expectTypeOf<typeof body>().toEqualTypeOf([] as string[])
    },
    {
      body: t.ArrayString(t.String())
    }
  )
}

// Type error assertions
{
  new Elysia().get(
    '/',
    // @ts-expect-error
    () => form({ file: 'a' }),
    {
      response: t.Form({
        name: t.String(),
        file: t.File()
      })
    }
  )
}
```

### Type Test Compilation
Type tests are validated through TypeScript compilation:
```json
{
  "compilerOptions": {
    "strict": true,
    "noEmit": true
  },
  "include": ["test/types/**/*"]
}
```

Executed via: `tsc --project tsconfig.test.json`

---

## Representative Test Snippet

**From `/test/core/elysia.test.ts`:**

```typescript
import { Elysia, t } from '../../src'
import { describe, expect, it } from 'bun:test'
import { req } from '../utils'

describe('Edge Case', () => {
  it('handle state', async () => {
    const app = new Elysia()
      .state('a', 'a')
      .get('/', ({ store: { a } }) => a)
    const res = await app.handle(req('/'))

    expect(await res.text()).toBe('a')
  })

  it("don't return HTTP 10", async () => {
    const app = new Elysia().get('/', ({ set }) => {
      set.headers.Server = 'Elysia'
      return 'hi'
    })

    const res = await app.handle(req('/'))
    expect(res.status).toBe(200)
  })

  it('has no side-effect', async () => {
    const app = new Elysia()
      .get('/1', ({ set }) => {
        set.headers['x-server'] = 'Elysia'
        return 'hi'
      })
      .get('/2', () => 'hi')

    const res1 = await app.handle(req('/1'))
    const res2 = await app.handle(req('/2'))
    // assertions...
  })
})
```

---

## Lint / Format / Typecheck Commands

| Command | Purpose |
|---------|---------|
| `bun test` | Run all functionality tests |
| `tsc --project tsconfig.test.json` | Type check test files |
| `npm run deadcode` (knip) | Detect unused code |
| Custom lint via eslintrc | ESLint configuration (see `.eslintrc.json`) |
| Prettier (via `.prettierrc`) | Code formatting: tabs, no semicolons, single quotes |

### ESLint Config
```json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:sonarjs/recommended"
  ],
  "ignorePatterns": ["example/*", "test/**/*"]
}
```

Note: Tests are ignored from linting.

### Prettier Config
```json
{
  "useTabs": true,
  "tabWidth": 4,
  "semi": false,
  "singleQuote": true,
  "trailingComma": "none"
}
```

---

## CI Configuration

**.github/workflows/ci.yml** - Runs on push and pull requests:

1. **Checkout** - Uses actions/checkout@v4
2. **Setup Bun** - Uses oven-sh/setup-bun@v1 (latest)
3. **Install** - `bun install`
4. **Build** - `bun run build`
5. **Test** - `bun run test` (all three: functionality + types + node)
6. **Cloudflare** - `bun run test:cf` (on PR only, publishes preview)

The CI runs the complete test suite on every push and PR, including:
- Bun functionality tests
- TypeScript type checking
- Node.js CJS/ESM compatibility tests
- Cloudflare Workers adapter tests

---

## Pre-commit Hooks

**No pre-commit hooks detected** - ESLint is configured but not integrated via Husky or git hooks. Tests must be run manually or through CI.

---

## Coverage Approach

**No explicit coverage measurement** - The project uses:
1. **Comprehensive test coverage** - 100+ test files covering all features
2. **Type safety** - Heavy type-level testing with expectTypeOf assertions
3. **Multi-runtime testing** - Node.js CJS, ESM, Cloudflare Workers, and Bun tests
4. **No coverage reports** - No Istanbul/nyc integration observed

---

## Summary

**Testing Idiom**: Elysia embraces **Bun's native testing** with a lightweight, synchronous approach. Routes are tested by invoking `.handle(Request)` directly without server instances. Type safety is paramount, with dedicated type-level test files validated at compile time. The project maintains high quality through comprehensive test organization, multi-runtime compatibility checks, and strong TypeScript inference validation.

**Key Characteristics**:
- Bun-native, no Jest/Vitest overhead
- Request-based testing, no mock servers
- First-class type validation with `expect-type`
- Multi-runtime compatibility (Bun, Node, Cloudflare)
- CI validates all test suites automatically
- No external mocking libraries

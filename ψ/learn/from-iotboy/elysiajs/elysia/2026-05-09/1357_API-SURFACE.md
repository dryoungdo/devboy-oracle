# Elysia Public API Surface (v1.4.28)

## Overview
Elysia is an ergonomic TypeScript web framework with full-stack type inference. The API surface is highly chainable and type-safe, powered by Sinclair TypeBox for schema validation and 7 generic parameters for state tracking.

---

## 1. The Elysia Class — Core Instance

### Primary Type Parameters
```typescript
Elysia<
  BasePath extends string = '',           // Route prefix
  Singleton extends SingletonBase = {...},  // Persistent: decorator, store, derive, resolve
  Definitions extends DefinitionBase = {},  // Type definitions (typebox, error)
  Metadata extends MetadataBase = {},      // Schema, macro, parser, response metadata
  Routes extends RouteBase = {},            // Type-level route registry
  Ephemeral extends EphemeralType = {},     // Scoped context (derive, resolve, schema)
  Volatile extends EphemeralType = {}       // Request-local context
>
```

### Route Methods (All Chainable)
- **HTTP Verbs**: `.get()`, `.post()`, `.put()`, `.patch()`, `.delete()`, `.options()`, `.head()`, `.trace()`, `.connect()`
- **WebSocket**: `.ws(path, options)` — register WebSocket endpoint
- **Signature**: Each HTTP method accepts `(path: string, handler, hook?: LocalHook) => Elysia`

### Plugin/Module Composition
- **`.use(plugin)`** — import Elysia instance, function, Promise, or ES module
- **`.group(prefix, [schema], callback)`** — encapsulate routes with prefix + optional schema
- **`.modules`** — getter returning PromiseGroup for lazy-loaded module resolution

### State Management
- **`.state(name, value)`** — define global mutable state (store)
- **`.state(store)`** — bulk state definition
- **`.state({ as: 'override' }, ...)`** — override existing state
- **`.store`** — getter to access current state object
- **`.decorator(name, value)`** — add method to Context
- **`.decorator(decorators)`** — bulk decorator definition
- **`.decorate(...)`** — alias for decorator

### Lifecycle Hooks (Chainable)
- **`.onStart(callback)`** — before server starts
- **`.onStop(callback)`** — after server stops
- **`.onRequest(callback)`** — on each incoming request
- **`.onParse(callback)`** — before body parsing
- **`.onTransform(callback)`** — transform/derive context (via `.derive()` or direct)
- **`.onBeforeHandle(callback)`** — before handler execution
- **`.onAfterHandle(callback)`** — after handler returns
- **`.onAfterResponse(callback)`** — after response sent
- **`.onError(callback)`** — on error

### Context Extensions
- **`.derive(transform)`** — add derived properties per-request
- **`.resolve(resolver)`** — add resolved properties per-request (async-first)
- **`.model(name, schema)`** — register reusable schema type
- **`.macro(name, macro)` | `.macro(macros)`** — define route macros (reusable inline hooks)

### Metadata & Compilation
- **`.compile()`** — precompile routes and handlers to function
- **`.listen(port | options, callback)`** — start server
- **`.stop([closeActive])`** — stop server
- **`.routes`** — getter returning `InternalRoute[]` history
- **`.config`** — configuration object (adapter, prefix, serve options, etc.)

### Type/Schema Definition
- **Constructor config**: `new Elysia({ prefix?, adapter?, serve?, detail?, tags?, ... })`

---

## 2. The Exported `t` (TypeBox Re-export + Extensions)

Elysia re-exports and extends `@sinclair/typebox/Type`:

### Core TypeBox Types
- `t.String()`, `t.Number()`, `t.Boolean()`, `t.Integer()`
- `t.Object({...})`, `t.Array(T)`, `t.Enum()`, `t.Union()`
- `t.Optional()`, `t.Required()`, `t.Date()`, `t.Unsafe()`
- `t.Ref()`, `t.Module()` — for reusable schemas

### Elysia-Specific Extensions
- `t.File(options?)` — single file validation
- `t.Files(options?)` — multiple files array
- `t.Form(schema)` — FormData with nested schema
- `t.Numeric(property?)` — coerces string to number
- `t.UnionEnum(values)` — union of literal enums
- `t.ArrayBuffer` — ArrayBuffer validation
- `t.Transform(type)` — codec for encode/decode

### Standard Schema V1 Support
Types compatible with `~standard` schema interface (Zod, Valibot, etc.)

---

## 3. Context Object Shape — What Handlers Receive

### Type: `Context<Route, Singleton, Path>`

#### Standard Properties
```typescript
{
  // Request Body
  body: Route['body'] & Resolve['body']
  
  // Query String Parameters
  query: Route['query'] | { [key: string]: string | undefined }
  
  // Path Parameters (extracted from :id, :name, etc.)
  params: Route['params'] | ResolvePath<Path>
  
  // Request Headers
  headers: Route['headers'] | { [key: string]: string | undefined }
  
  // HTTP Cookies (signed/validated)
  cookie: Record<string, Cookie<T>>
  
  // Store (global mutable state)
  store: Singleton['store']
  
  // Decorators (custom methods added via .decorate())
  ...Singleton['decorator']
  
  // Derived Properties (per-request)
  ...Singleton['derive']
  ...Ephemeral['derive']
  ...Volatile['derive']
  
  // Resolved Properties (async-first)
  ...Singleton['resolve']
  ...Ephemeral['resolve']
  ...Volatile['resolve']
}
```

#### Response Control (`Context.set`)
```typescript
{
  headers: HTTPHeaders                              // Set response headers
  status?: number | keyof StatusMap                  // Set HTTP status code
  redirect?: string                                  // Set Location header
  cookie?: Record<string, ElysiaCookie>             // Set cookies
}
```

#### Context-Specific Methods
```typescript
{
  path: string                  // Actual URL path (e.g., '/user/9')
  route: string                 // Registered route pattern (e.g., '/user/:id')
  request: Request              // Native Web API Request
  server: Server | null         // Bun.Server or null
  redirect(url, status?): Response
  status<Code, T>(code, response?): ElysiaCustomStatusResponse
}
```

---

## 4. Lifecycle Events & Hook Signatures

### Hook Types (LifeCycleType)
- `'global'` — singleton-wide (before all routes)
- `'scoped'` — group-level (before group routes)
- `'local'` — route-specific (before single route)

### Event Hooks (in execution order)
```typescript
onStart(callback: (server: Server) => void): Elysia
onRequest(callback: (ctx: Context) => void): Elysia
onParse(callback: (req: Request, contentType: string) => any): Elysia
onTransform(callback: (ctx: Context) => Derivative): Elysia
onBeforeHandle(callback: (ctx: Context) => void): Elysia
onAfterHandle(callback: (ctx: Context, response: any) => void): Elysia
onAfterResponse(callback: (ctx: Context) => void): Elysia
onError(callback: (ctx: ErrorContext, error: Error) => Response): Elysia
onStop(callback: () => void): Elysia
```

### Scoped Variants
Each hook supports `{ as: 'global' | 'scoped' | 'local' }` option:
```typescript
.onBeforeHandle({ as: 'global' }, callback)
.onBeforeHandle({ as: 'scoped' }, callback)
.onBeforeHandle(callback)  // defaults to 'local'
```

### ErrorContext Shape
```typescript
{
  // All standard Context properties
  body, query, params, headers, cookie, store, decorator, derive, resolve
  
  // Error-specific
  path: string
  route: string
  request: Request
  server: Server | null
}
```

---

## 5. Type Inference & Generic State Tracking

### Singleton (Persistent Across Routes)
```typescript
{
  decorator: {}           // Custom methods (.decorate())
  store: {}               // Global state (.state())
  derive: {}              // Global derived properties (.derive({ as: 'global' }))
  resolve: {}             // Global resolved properties (.resolve({ as: 'global' }))
}
```

### Ephemeral (Group-Scoped)
```typescript
{
  derive: {}              // Scoped derived properties
  resolve: {}             // Scoped resolved properties
  schema: {}              // Scoped input schema
  standaloneSchema: {}    // Standalone validator schema
  response: {}            // Response schema union
}
```

### Volatile (Request-Local)
```typescript
{
  derive: {}              // Local derived properties
  resolve: {}             // Local resolved properties
  schema: {}              // Route input schema
  standaloneSchema: {}    // Standalone validator schema
  response: {}            // Route response schema
}
```

---

## 6. Eden Client — Type-Safe API Client

Generated from a server's routes via the type system.

### CreateEden Type
```typescript
CreateEden<Path, { method: CreateEdenResponse<...> }>
```

### Client Generation
Clients are generated at compile time from route type inference:
- No runtime code generation
- Full TypeScript support (request validation, response typing)
- Works across frameworks via standard type exports

### Usage Pattern
```typescript
// Server creates routes
const app = new Elysia()
  .post('/user', (ctx) => ({ id: 1, name: 'John' }), {
    response: t.Object({ id: t.Number(), name: t.String() })
  })

// Client infers types from route signatures
type AppRoutes = typeof app  // Elysia type captures all routes
```

---

## 7. Adapters — Runtime Environment Support

### Available Adapters
- **BunAdapter** (default) — native Bun.serve()
- **WebStandardAdapter** — Web Standard (Fetch API, Cloudflare Workers)
- Additional adapters via `elysia` peer dependency

### Adapter Interface (ElysiaAdapter)
```typescript
{
  name: string
  listen(app): (options, callback?) => void    // Start server
  stop?(app, closeActive?): Promise<void>      // Stop server
  isWebStandard?: boolean
  handler: {
    mapResponse(response, set): unknown
    mapEarlyResponse(response, set): unknown
    mapCompactResponse(response): unknown
    createStaticHandler?(handle, hooks, headers): () => unknown
    createNativeStaticHandler?(handle, hooks, set): () => Promise<Response>
  }
  composeHandler: { ... }   // Handler composition options
  ws?(app, path, options): void  // WebSocket support
}
```

### Configuration
```typescript
new Elysia({
  adapter: BunAdapter,          // ElysiaAdapter instance
  serve: { port: 3000, ... }    // Bun.serve options
})
```

---

## 8. Error Class Hierarchy

### Error Classes
```typescript
class InternalServerError extends Error {
  code = 'INTERNAL_SERVER_ERROR'
  status = 500
}

class NotFoundError extends Error {
  code = 'NOT_FOUND'
  status = 404
}

class ParseError extends Error {
  code = 'PARSE'
  status = 400
}

class ValidationError extends Error {
  code = 'VALIDATION'
  status = 400
}

class InvalidFileType extends Error {
  code = 'INVALID_FILE_TYPE'
  status = 400
}

class InvalidCookieSignature extends Error {
  code = 'INVALID_COOKIE_SIGNATURE'
  status = 400
}
```

### Custom Status Response
```typescript
class ElysiaCustomStatusResponse<Code, T> {
  code: Status
  response: T
  constructor(code: Code | keyof StatusMap, response: T)
}

status(code, response?) => ElysiaCustomStatusResponse
```

---

## 9. Public Utilities & Helpers

### Exported Functions
```typescript
redirect(url: string, status?: number): Response
form(key: string, value: any): FormData          // Create FormData
sse(payload: SSEPayload): Response                // Server-Sent Events
mergeHook(...hooks): MergedHook                   // Merge hook definitions
checksum(input: string): string                   // Hash for deduplication
cloneInference(inference): Inference              // Clone type inference state
deduplicateChecksum(seed: string): string         // Plugin deduplication
replaceUrlPath(path: string): string              // Normalize paths
StatusMap, InvertedStatusMap                      // Status code maps
```

### Validators
```typescript
getSchemaValidator(schema): TypeCheck             // Compile schema validator
getResponseSchemaValidator(schema): TypeCheck     // Compile response validator
validationDetail(error): ValidationDetail         // Extract error details
fileType(file: File): Promise<FileTypeResult>    // Detect file MIME type
```

### Trace API
```typescript
ELYSIA_TRACE: Symbol                              // Trace middleware marker
type TraceEvent = { ... }                         // Trace event structure
type TraceListener = (event: TraceEvent) => void
type TraceHandler = (trace: TraceListener) => void
```

---

## 10. HTTP Features — Streaming, Files, Cookies, Redirects

### File Handling
```typescript
t.File(options?)                     // Single file upload
t.Files(options?)                    // Multiple files array

// Handler receives File or File[]
.post('/upload', ({ body: { file } }) => {
  console.log(file.name, file.type, file.size)
})
```

### Cookie Management
```typescript
context.cookie.session             // Read signed cookie
set.cookie.session = {
  value: 'token',
  httpOnly: true,
  sameSite: 'strict',
  maxAge: 3600,
  domain?: string,
  path?: string,
  secure?: boolean,
  priority?: 'low' | 'medium' | 'high',
  partitioned?: boolean
}

serializeCookie(name, value, options): string
```

### Redirect Responses
```typescript
context.set.redirect = '/new-path'
redirect('/path', 301)  // Response.redirect()
```

### Streaming Responses
```typescript
.get('/stream', () => {
  return new Response(ReadableStream)
})
```

### Server-Sent Events
```typescript
sse(payload: {
  data?: string
  event?: string
  id?: string
  retry?: number
}): Response
```

### FormData
```typescript
t.Form({
  file: t.File(),
  name: t.String(),
  tags: t.Array(t.String())
})

form('key', value)  // Helper
```

---

## 11. Configuration & Advanced Features

### ElysiaConfig Options
```typescript
{
  prefix?: string                    // Route prefix (e.g., '/v1')
  adapter?: ElysiaAdapter           // Runtime adapter
  serve?: Partial<Serve>            // Bun.serve config
  name?: string                     // Instance name (debugging)
  seed?: unknown                    // Plugin deduplication seed
  detail?: DocumentDecoration       // OpenAPI metadata
  tags?: DocumentDecoration['tags'] // OpenAPI tags
  aot?: boolean                     // Ahead-of-time compilation
  strictPath?: boolean              // Strict path matching
  websocket?: WSHandler             // WebSocket options
  cookie?: CookieOptions & {
    sign?: true | string | string[]  // Cookie signing keys
  }
  analytic?: boolean                // Detailed dependency info
  encodeSchema?: boolean            // Auto-encode schema transforms
  precompile?: boolean | {
    compose?: boolean               // Dynamic handler generation
    schema?: boolean                // Schema AOT compilation
  }
}
```

### Compile Strategy
```typescript
.compile()                           // Force precompilation
.config.aot = true                   // Enable AOT compilation
.config.precompile = { ... }         // Fine-grained control
```

### WebSocket Support
```typescript
.ws('/ws', {
  open(ws) { },
  message(ws, message) { },
  close(ws) { },
  drain?(ws) { }
})
```

---

## 12. Macro System — Route Reuse

Define reusable route patterns with type safety:

```typescript
.macro({
  admin: (options) => ({
    beforeHandle: isAdmin,
    response: {
      200: t.Object({ ... })
    }
  })
})

.get('/admin/users', ({ admin }) => ({ ... }), {
  admin: true
})
```

---

## 13. Export Surface

### Main Module
```typescript
export { Elysia }
export { t }  // TypeBox + extensions
export { validationDetail, fileType }
export { Context, PreContext, ErrorContext }
export { serializeCookie, Cookie, type CookieOptions }
export { redirect, form, sse, mergeHook, checksum, StatusMap, ... }
export { status, ParseError, ValidationError, NotFoundError, ... }
export { ELYSIA_TRACE, TraceEvent, TraceListener, ... }
export { getSchemaValidator, getResponseSchemaValidator }
export { file, ElysiaFile }
export { env }
export type { ElysiaAdapter }
```

### Sub-modules
- `elysia/ws` — WebSocket types & utilities
- `elysia/compose` — Handler composition
- `elysia/context` — Context type definitions
- `elysia/cookies` — Cookie utilities
- `elysia/error` — Error classes
- `elysia/schema` — Schema utilities
- `elysia/type-system` — TypeBox integration
- `elysia/adapter` — Adapter types
- `elysia/universal` — Runtime-agnostic server
- `elysia/trace` — Trace API
- `elysia/utils` — Utility functions

---

## Summary

Elysia's API surface is organized around:

1. **Chainable Methods** — all modifications return `Elysia` for fluent composition
2. **Type Parameters** — 7 generics track decorator, store, derive, resolve, schema at compile time
3. **Context Injection** — handlers receive fully-typed context with store, decorators, derives, resolves
4. **Lifecycle Hooks** — 9 named hooks (onStart, onRequest, onParse, etc.) at 3 scopes (global, scoped, local)
5. **Flexible Composition** — `.use()` for plugins, `.group()` for prefixes, `.macro()` for patterns
6. **Runtime Adapters** — plug different runtimes (Bun, Cloudflare, Web Standard)
7. **Error Classes** — typed error handling with status codes
8. **TypeBox Integration** — full schema validation with file, form, and custom types
9. **State Management** — `.state()` for store, `.derive()` for computed values, `.resolve()` for async
10. **Zero-Overhead** — AOT compilation, static handler optimization, no reflection

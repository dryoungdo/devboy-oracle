# Elysia Quick Reference (v1.4.28)

## What is Elysia?

Elysia is an ergonomic, Bun-native TypeScript framework for building high-performance HTTP APIs and WebSocket servers. Built on Bun's fast HTTP server, it provides end-to-end type safety via TypeScript inference and TypeBox schema validation, unified type definitions for runtime validation and documentation, and an intuitive fluent API that prioritizes developer experience. With automatic code generation (AOT) and dynamic compilation modes, it's 18x faster than Express (TechEmpower benchmarks) while delivering zero-cost abstractions through compile-time optimizations.

---

## Installation & Hello World

```bash
bun add elysia
```

**Minimal example:**
```typescript
import { Elysia } from 'elysia'

new Elysia()
  .get('/', () => 'Hello Elysia')
  .listen(3000)
```

---

## Routing

All HTTP methods are supported with identical signatures. Routes are type-safe: params, query, body, headers, and responses are validated at runtime and typed at compile-time.

### Basic Routes
```typescript
.get('/path', () => 'response')
.post('/path', ({ body }) => body)
.put('/path', ({ body }) => body)
.patch('/path', ({ body }) => body)
.delete('/path', () => 'deleted')
.head('/path', () => {})
.all('/path', () => 'any method')  // GET, POST, PUT, PATCH, DELETE, HEAD
```

### Path Parameters
```typescript
.get('/user/:id', ({ params: { id } }) => id, {
  params: t.Object({
    id: t.String()
  })
})

.get('/post/:id/comment/:cid', ({ params: { id, cid } }) => ({id, cid}))
.get('/file/*', () => 'wildcard match')  // matches /file/anything/nested
```

### Query Strings
```typescript
.get('/search', ({ query }) => query, {
  query: t.Object({
    q: t.String(),
    limit: t.Optional(t.Number())
  })
})
// /search?q=hello&limit=10 → { q: 'hello', limit: 10 }
```

### Request Body
```typescript
.post('/user', ({ body }) => body, {
  body: t.Object({
    name: t.String(),
    email: t.String({ format: 'email' })
  })
})
```

### Headers
```typescript
.get('/auth', ({ headers }) => headers, {
  headers: t.Object({
    authorization: t.String()
  })
})
```

### Response Types
```typescript
.get('/', () => 'string')           // text/plain
.get('/', () => ({ a: 1 }))         // application/json
.get('/', () => Bun.file('path'))   // streams file
.get('/', () => new Response(''))    // raw Response
.get('/', () => new Error('fail'))   // error handling
```

### Grouping Routes
```typescript
.group('/api', (app) =>
  app
    .get('/users', () => [])
    .post('/users', ({ body }) => body)
    .get('/users/:id', ({ params: { id } }) => id)
)
// Routes become /api/users, /api/users/:id
```

---

## Schema Validation with TypeBox

TypeBox (`t`) provides a unified schema for both runtime validation and compile-time types. Schemas are used in route handlers and automatically validate incoming data.

### Primitive Types
```typescript
t.String()              // string
t.Number()              // number, coerced from "123"
t.Boolean()             // boolean, coerced from "true"/"false"
t.Integer()             // integer only
t.Literal('admin')      // literal value
t.Optional(t.String())  // string | undefined
```

### Object & Array
```typescript
t.Object({
  name: t.String(),
  age: t.Number(),
  role: t.Optional(t.String({ default: 'user' }))
})

t.Array(t.String())     // string[]
t.Array(t.Number())     // number[]
```

### Validation Options
```typescript
t.String({ minLength: 3, maxLength: 100 })
t.Number({ minimum: 1, maximum: 100 })
t.String({ pattern: '^[a-z]+$' })  // regex
t.String({ format: 'email' })
t.String({ format: 'uuid' })
```

### Union & Intersection
```typescript
t.Union([t.String(), t.Number()])  // string | number
t.Intersection([
  t.Object({ a: t.String() }),
  t.Object({ b: t.Number() })
])
```

### Schema in Routes
Schemas validate at **runtime** and **compile-time**:
```typescript
.post('/login', ({ body }) => ({ token: 'abc' }), {
  body: t.Object({
    username: t.String(),
    password: t.String({ minLength: 8 })
  }),
  response: t.Object({
    token: t.String()
  })
})
// Invalid body → 422 Unprocessable Entity with error details
// Invalid response → 500 Internal Server Error
```

---

## Request Parsing & Transformation

### Content-Type Parsing
```typescript
.post('/data', ({ body }) => body, {
  parse: 'json'              // application/json (default)
  // parse: 'text'           // text/plain
  // parse: 'formdata'       // multipart/form-data
  // parse: 'urlencoded'     // application/x-www-form-urlencoded
})
```

### Custom Parsers (Global)
```typescript
.onParse(async ({ request, contentType }) => {
  if (contentType === 'application/custom') {
    return await request.text()
  }
})
```

### Transform Hook (Per-Route)
```typescript
.post('/user', ({ body }) => body, {
  body: t.Object({ id: t.Number(), name: t.String() }),
  transform: ({ body }) => {
    // Modify body before validation
    body.id = body.id + 1
    body.name = body.name.toUpperCase()
  }
})
```

---

## Plugin System

Plugins are reusable Elysia instances. They encapsulate routes, hooks, state, decorators, and type information.

### Define a Plugin
```typescript
const logger = new Elysia({ name: 'logger' })
  .decorate('log', (msg: string) => console.log(msg))
  .state('logCount', 0)
  .onRequest(({ store }) => {
    store.logCount++
  })
```

### Register a Plugin
```typescript
const app = new Elysia()
  .use(logger)
  .get('/', ({ log, store: { logCount } }) => {
    log('handling request')
    return { count: logCount }
  })
```

### Plugin Deduplication
Plugins with the same `name` are merged (not duplicated):
```typescript
new Elysia({ name: 'auth' })
  // ...

app.use(auth).use(auth)  // registered once
```

---

## Lifecycle Hooks

Hooks execute at specific points in request processing. **Global** hooks run for all routes; **local** hooks run only on their route.

### Hook Execution Order
1. **onRequest** → Request received
2. **onParse** → Body parsed
3. **transform** → Context modified
4. **beforeHandle** → Before handler
5. **[Handler]** → Route handler executes
6. **afterHandle** → After handler
7. **mapResponse** → Response object created
8. **afterResponse** → Response sent to client

### Global Hooks
```typescript
.onRequest(({ set, url }) => {
  set.headers['X-Custom'] = 'value'
})

.onParse(({ request, contentType }) => {
  // Custom body parser
})

.onTransform(({ body, params, query }) => {
  // Transform any context before main handler
})

.onBeforeHandle(({ query }) => {
  // Early return stops handler
  if (query?.skip) return 'early response'
})

.onAfterHandle(({ response }) => {
  // Modify response after handler
  return { wrappedBy: response }
})

.onAfterResponse(() => {
  // Fire-and-forget after response sent
  // Good for logging, cleanup
})

.onError(({ code, error, set }) => {
  if (code === 'VALIDATION') {
    set.status = 422
    return { error: 'Invalid input' }
  }
})
```

### Local Hooks (Per-Route)
```typescript
.get('/protected', ({ user }) => user, {
  beforeHandle: ({ query }) => {
    if (!query.token) return new Error('Unauthorized')
  },
  afterHandle: (ctx) => {
    ctx.set.headers['Cache-Control'] = 'no-cache'
  }
})
```

### Hook Overrides
```typescript
.get('/admin', () => 'admin', {
  as: 'override'  // replaces global hooks, doesn't merge
})
```

---

## Context Manipulation

### Decorators (Custom Methods)
Add reusable functions to context:
```typescript
.decorate('now', () => Date.now())
.decorate('uuid', () => crypto.randomUUID())

.get('/', ({ now, uuid }) => ({
  timestamp: now(),
  id: uuid()
}))
```

### State (Mutable Store)
Global state shared across requests:
```typescript
.state('counter', 0)
.state({ db: new Database() })

.get('/', ({ store: { counter, db } }) => ({
  count: ++counter,
  // db is shared (be careful with mutations!)
}))
```

### Derive (Per-Request Values)
Compute values that depend on context (request-scoped):
```typescript
.derive(({ headers }) => ({
  user: parseJWT(headers.authorization),
  isAdmin: headers['x-admin'] === 'true'
}))

.get('/', ({ user, isAdmin }) => ({ user, isAdmin }))
```

### Resolve (Lazy Derivation)
Like `derive` but promises are awaited:
```typescript
.resolve(async ({ params: { id } }) => ({
  user: await db.user.findById(id)
}))

.get('/user/:id', ({ user }) => user)
```

---

## WebSocket Support

WebSocket connections with validation and type safety.

### Basic WebSocket
```typescript
new Elysia()
  .ws('/chat', {
    open(ws) {
      console.log('Client connected:', ws.id)
    },
    message(ws, message) {
      ws.send(message)  // echo
      ws.publish('chat', message)  // broadcast
    },
    close(ws) {
      console.log('Client disconnected:', ws.id)
    }
  })
  .listen(3000)
```

### WebSocket Methods
```typescript
ws.send(data)              // send to this client
ws.sendText(text)          // send string
ws.sendBinary(bytes)       // send binary
ws.ping(data?)             // ping message
ws.publish(topic, data)    // broadcast to subscribers
ws.subscribe(topic)        // join broadcast group
ws.unsubscribe(topic)      // leave group
ws.close(code?, reason?)   // close connection
```

### Message Validation
```typescript
.ws('/messages', {
  message(ws, message) {
    ws.send(message)
  }
}, {
  body: t.Object({
    type: t.String(),
    text: t.String()
  })
})
```

---

## Error Handling

### Status Codes
```typescript
.get('/', ({ set }) => {
  set.status = 404
  return 'Not found'
})

// Or use status helper:
import { status } from 'elysia'

.get('/', () => status(404, 'Not found'))
```

### Response Errors
```typescript
.get('/', () => {
  throw new Error('Something failed')
  // Returns 500 with error message
})
```

### Custom Error Handler
```typescript
.onError(({ code, error, set }) => {
  if (code === 'NOT_FOUND') {
    set.status = 404
    return { error: 'Route not found' }
  }

  if (code === 'VALIDATION') {
    set.status = 422
    return { error: 'Invalid input', details: error }
  }

  // Default 500
  return { error: 'Internal server error' }
})
```

---

## Response Mapping

Transform all responses (e.g., wrap in envelope, add metadata).

```typescript
.mapResponse(({ response }) => {
  return {
    status: 'ok',
    data: response,
    timestamp: Date.now()
  }
})

.get('/', () => 'hello')
// Returns: { status: 'ok', data: 'hello', timestamp: 1234567890 }
```

---

## Cookies

Parse and set cookies with optional signing.

### Parse Cookies
```typescript
.get('/', ({ cookie: { session } }) => {
  return { sessionId: session.value }
}, {
  cookie: t.Object({
    session: t.Optional(t.String())
  })
})
```

### Set Cookies
```typescript
.get('/', ({ set }) => {
  set.cookie.session = {
    value: 'abc123',
    maxAge: 60 * 60 * 24,  // 1 day
    httpOnly: true,
    secure: true
  }
  return 'ok'
})
```

### Signed Cookies
```typescript
new Elysia({
  cookie: { sign: 'secret-key' }  // auto-sign all cookies
})

.get('/', ({ set }) => {
  set.cookie.token = {
    value: 'data',
    signed: true  // will be signed with secret
  }
})
```

---

## package.json Scripts

```json
{
  "scripts": {
    "dev": "bun run --watch src/index.ts",
    "build": "bun build src/index.ts --outdir dist",
    "start": "bun dist/index.js",
    "test": "bun test"
  }
}
```

**In Elysia source (from package.json):**
- `test` — Run full test suite (functionality, types, Node.js compat)
- `test:functionality` — Bun tests + import checks
- `test:types` — TypeScript type checking
- `test:node` — Node.js compatibility (CJS/ESM)
- `dev` — Watch example/a.ts with hot reload
- `build` — Esbuild compilation to dist/

---

## Performance Characteristics

- **18x faster than Express** (TechEmpower benchmarks)
- **Bun's native HTTP server** — single-threaded event loop, ~600k req/sec on mid-range hardware
- **Ahead-of-Time (AOT) compilation** — optional route precompilation via `precompile: { compose: true, schema: true }`
- **Dynamic mode** — Just-in-Time compilation (default) for fast startup
- **Zero-cost abstractions** — TypeScript types erased at runtime; validation compiled to machine code
- **Stream support** — Efficient file serving, ReadableStream responses with backpressure handling

---

## Advanced Features

### Type Coercion
Query/param strings are auto-coerced: `?id=123` → `123` (number), `?active=true` → `true` (boolean).

### File Upload
```typescript
.post('/upload', ({ body: { file } }) => ({
  name: file.name,
  size: file.size,
  type: file.type
}), {
  body: t.Object({
    file: t.File()
  })
})
```

### Macros
Reusable, type-safe route builders:
```typescript
.macro(({ onBeforeHandle }) => ({
  isAdmin: (handler) => onBeforeHandle(() => {
    // verify admin
  })
}))

.get('/', () => 'admin panel', { isAdmin: true })
```

### Trace & Introspection
```typescript
app.routes  // Array of registered routes
app.server  // Bun.serve instance (after listen())
```

---

## Key Differences from Express

| Feature | Elysia | Express |
|---------|--------|---------|
| **Runtime** | Bun (modern, fast) | Node.js (universal) |
| **Type Safety** | End-to-end (TS + runtime) | Optional (TS helpers only) |
| **Validation** | Built-in (TypeBox) | Manual (joi, zod, etc.) |
| **Middleware** | Hooks (ordered lifecycle) | Middleware stack |
| **Performance** | 18x faster | Baseline |
| **Bundle** | Tree-shakeable | Large dependency tree |

---

## Resources

- **Docs:** https://elysiajs.com
- **GitHub:** https://github.com/elysiajs/elysia
- **Discord:** https://discord.gg/eaFJ2KDJck
- **TypeBox:** https://github.com/sinclairzx81/typebox

---

**Version:** 1.4.28  
**Last Updated:** 2025-03-17  
**Target Audience:** Developers building REST APIs, WebSocket servers, or real-time applications with Bun

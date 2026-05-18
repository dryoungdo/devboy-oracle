# Elysia Core Architecture: Key Code Snippets

## 1. Elysia Class Declaration & Constructor

**File:** `/src/index.ts:190-270`

```typescript
export default class Elysia<
	const in out BasePath extends string = '',
	const in out Singleton extends SingletonBase = {
		decorator: {}
		store: {}
		derive: {}
		resolve: {}
	},
	const in out Definitions extends DefinitionBase = {
		typebox: {}
		error: {}
	},
	const in out Metadata extends MetadataBase = {
		schema: {}
		standaloneSchema: {}
		macro: {}
		macroFn: {}
		parser: {}
		response: {}
	},
	const in out Routes extends RouteBase = {},
	const in out Ephemeral extends EphemeralType = {
		derive: {}
		resolve: {}
		schema: {}
		standaloneSchema: {}
		response: {}
	},
	const in out Volatile extends EphemeralType = {
		derive: {}
		resolve: {}
		schema: {}
		standaloneSchema: {}
		response: {}
	}
> {
	config: ElysiaConfig<BasePath>
	server: Server | null = null
	private dependencies: { [key: string]: Checksum[] } = {}

	'~Prefix' = '' as BasePath
	'~Singleton' = null as unknown as Singleton
	'~Definitions' = null as unknown as Definitions
	'~Metadata' = null as unknown as Metadata
	'~Ephemeral' = null as unknown as Ephemeral
	'~Volatile' = null as unknown as Volatile
	'~Routes' = null as unknown as Routes

	protected singleton = {
		decorator: {},
		store: {},
		derive: {},
		resolve: {}
	} as SingletonBase

	get store(): Singleton['store'] {
		return this.singleton.store
	}

	get decorator(): Singleton['decorator'] {
		return this.singleton.decorator
	}
}
```

**Type System Explanation:**
- Generic parameters use `const in out` for branded type parameters that flow through the chain
- `Singleton`: Global per-app context (decorator, store, derive, resolve)
- `Ephemeral`: Scoped per-route context 
- `Volatile`: Local per-request context
- Virtual properties (`~Prefix`, etc) enable type narrowing without runtime overhead

---

## 2. GET Route Registration with Type Inference

**File:** `/src/index.ts:5747-5810`

```typescript
get<
	const Path extends string,
	const Input extends Metadata['macro'] &
		InputSchema<keyof Definitions['typebox'] & string>,
	const Schema extends IntersectIfObjectSchema<
		MergeSchema<
			UnwrapRoute<
				Input,
				Definitions['typebox'],
				JoinPath<BasePath, Path>
			>,
			MergeSchema<
				Volatile['schema'],
				MergeSchema<Ephemeral['schema'], Metadata['schema']>
			>
		>,
		Metadata['standaloneSchema'] &
			Ephemeral['standaloneSchema'] &
			Volatile['standaloneSchema']
	>,
	const Decorator extends Singleton & {
		derive: Ephemeral['derive'] & Volatile['derive']
		resolve: Ephemeral['resolve'] & Volatile['resolve']
	},
	const MacroContext extends {} extends Metadata['macroFn']
		? {}
		: MacroToContext<
				Metadata['macroFn'],
				Omit<Input, NonResolvableMacroKey>,
				Definitions['typebox']
			>,
	const Handle extends {} extends MacroContext
		? InlineHandlerNonMacro<NoInfer<Schema>, NoInfer<Decorator>>
		: InlineHandler<
				NoInfer<Schema>,
				NoInfer<Decorator>,
				MacroContext
			>
>(
	path: Path,
	handler: Handle,
	hook?: LocalHook<
		Input,
		Schema & MacroContext,
		Decorator,
		Definitions['error'],
		keyof Metadata['parser']
	>
): Elysia<...>
```

**Type Flow Explanation:**
- `Path` → `UnwrapRoute` extracts body/query/params/headers schemas from path pattern
- `Input` macro merges with schema definitions
- `Schema` intersects ephemeral + volatile + metadata schemas for complete request validation
- `Decorator` is Singleton + current ephemeral/volatile derives (full context)
- `MacroContext` is computed from `Metadata['macroFn']` for route-level transformations
- Handler receives fully typed `Schema` & `Decorator` (no type leakage)

---

## 3. POST Route Registration (Same Type Inference Pattern)

**File:** `/src/index.ts:5857-5910`

```typescript
post<
	const Path extends string,
	const Input extends Metadata['macro'] &
		InputSchema<keyof Definitions['typebox'] & string>,
	const Schema extends IntersectIfObjectSchema<
		MergeSchema<
			UnwrapRoute<Input, Definitions['typebox'], JoinPath<BasePath, Path>>,
			MergeSchema<
				Volatile['schema'],
				MergeSchema<Ephemeral['schema'], Metadata['schema']>
			>
		>,
		Metadata['standaloneSchema'] &
			Ephemeral['standaloneSchema'] &
			Volatile['standaloneSchema']
	>,
	const Decorator extends Singleton & {
		derive: Ephemeral['derive'] & Volatile['derive']
		resolve: Ephemeral['resolve'] & Volatile['resolve']
	},
	const MacroContext extends {} extends Metadata['macroFn']
		? {}
		: MacroToContext<
				Metadata['macroFn'],
				Omit<Input, NonResolvableMacroKey>,
				Definitions['typebox']
			>,
	const Handle extends {} extends MacroContext
		? InlineHandlerNonMacro<NoInfer<Schema>, NoInfer<Decorator>>
		: InlineHandler<
				NoInfer<Schema>,
				NoInfer<Decorator>,
				MacroContext
			>
>(
	path: Path,
	handler: Handle,
	hook?: LocalHook<
		Input,
		Schema & MacroContext,
		Decorator,
		Definitions['error'],
		keyof Metadata['parser']
	>
): Elysia<...>
```

---

## 4. Schema-Validated Route Using typebox

**File:** `/example/schema.ts:1-61`

```typescript
import { Elysia, t } from '../src'

const app = new Elysia()
	.model({
		name: t.Object({
			name: t.String()
		}),
		b: t.Object({
			response: t.Number()
		}),
		authorization: t.Object({
			authorization: t.String()
		})
	})
	// Strictly validate response
	.get('/', () => 'hi')
	// Strictly validate body and response
	.post('/', ({ body, query }) => body.id, {
		body: t.Object({
			id: t.Number(),
			username: t.String(),
			profile: t.Object({
				name: t.String()
			})
		})
	})
	// Strictly validate query, params, and body
	.get('/query/:id', ({ query: { name }, params }) => name, {
		query: t.Object({
			name: t.String()
		}),
		params: t.Object({
			id: t.String()
		}),
		response: {
			200: t.String(),
			300: t.Object({
				error: t.String()
			})
		}
	})
	.guard(
		{
			headers: 'authorization'
		},
		(app) =>
			app
				.derive(({ headers }) => ({
					userId: headers.authorization
				}))
				.get('/', ({ userId }) => 'A')
				.post('/id/:id', ({ query, body, params, userId }) => body, {
					params: t.Object({
						id: t.Number()
					}),
					transform({ params }) {
						params.id = +params.id
					}
				})
	)
	.listen(3000)
```

**Schema Features:**
- `.model()` defines reusable schemas
- Routes accept `t.Object({...})` for structural validation
- Response schemas with status-based types (200, 300 variants)
- `.guard()` scopes schemas to subtrees

---

## 5. Sucrose Static Analyzer - Function Signature Parsing

**File:** `/src/sucrose.ts:46-133`

```typescript
export const separateFunction = (
	code: string
): [string, string, { isArrowReturn: boolean }] => {
	// Remove async keyword without removing space (both minify and non-minify)
	if (code.startsWith('async')) code = code.slice(5)
	code = code.trimStart()

	let index = -1

	// JSC: Starts with '(', is an arrow function
	if (code.charCodeAt(0) === 40) {
		index = code.indexOf('=>', code.indexOf(')'))

		if (index !== -1) {
			let bracketEndIndex = index
			while (bracketEndIndex > 0)
				if (code.charCodeAt(--bracketEndIndex) === 41) break

			let body = code.slice(index + 2)
			if (body.charCodeAt(0) === 32) body = body.trimStart()

			return [
				code.slice(1, bracketEndIndex),
				body,
				{ isArrowReturn: body.charCodeAt(0) !== 123 }
			]
		}
	}

	// V8: bracket is removed for 1 parameter arrow function
	if (/^(\w+)=>/g.test(code)) {
		index = code.indexOf('=>')
		let body = code.slice(index + 2)
		if (body.charCodeAt(0) === 32) body = body.trimStart()
		return [
			code.slice(0, index),
			body,
			{ isArrowReturn: body.charCodeAt(0) !== 123 }
		]
	}

	// Using function keyword
	if (code.startsWith('function')) {
		index = code.indexOf('(')
		const end = code.indexOf(')')
		return [
			code.slice(index + 1, end),
			code.slice(end + 2),
			{ isArrowReturn: false }
		]
	}

	// Probably Declare as method
	const start = code.indexOf('(')
	if (start !== -1) {
		const sep = code.indexOf('\n', 2)
		const parameter = code.slice(0, sep)
		const end = parameter.lastIndexOf(')') + 1
		const body = code.slice(sep + 1)
		return [
			parameter.slice(start, end),
			'{' + body,
			{ isArrowReturn: false }
		]
	}

	// Unknown case
	const x = code.split('\n', 2)
	return [x[0], x[1], { isArrowReturn: false }]
}

export const bracketPairRange = (parameter: string): [number, number] => {
	const start = parameter.indexOf('{')
	if (start === -1) return [-1, 0]

	let end = start + 1
	let deep = 1

	for (; end < parameter.length; end++) {
		const char = parameter.charCodeAt(end)
		if (char === 123) deep++
		else if (char === 125) deep--
		if (deep === 0) break
	}

	if (deep !== 0) return [0, parameter.length]
	return [start, end + 1]
}
```

**Hot Path Magic:**
- Sucrose parses stringified handler bodies to extract parameter names at **compile time**
- Uses char codes for perf (0-indexed ASCII: 40='(', 123='{', 125='}')
- Supports arrow functions, function declarations, and minified code
- Returns `[parameters, body, { isArrowReturn }]` tuple for code injection

---

## 6. Derive - Context Augmentation Primitive

**File:** `/src/index.ts:7454-7504`

```typescript
derive<
	const Derivative extends
		| Record<string, unknown>
		| ElysiaCustomStatusResponse<any, any, any>
		| void
>(
	transform: (
		context: Context<
			MergeSchema<
				Volatile['schema'],
				MergeSchema<Ephemeral['schema'], Metadata['schema']>,
				BasePath
			> &
				Metadata['standaloneSchema'] &
				Ephemeral['standaloneSchema'] &
				Volatile['standaloneSchema'],
			Singleton & {
				derive: Ephemeral['derive'] & Volatile['derive']
				resolve: Ephemeral['resolve'] & Volatile['resolve']
			}
		>
	) => MaybePromise<Derivative>
): Elysia<
	BasePath,
	Singleton,
	Definitions,
	Metadata,
	Routes,
	Ephemeral,
	{
		derive: Volatile['derive'] & ExcludeElysiaResponse<Derivative>
		resolve: Volatile['resolve']
		schema: Volatile['schema']
		standaloneSchema: Volatile['standaloneSchema']
		response: UnionResponseStatus<
			Volatile['response'],
			ExtractErrorFromHandle<Derivative>
		>
	}
>

/**
 * Derive new property for each request with access to `Context`.
 * If error is thrown, the scope will skip to handling error instead.
 *
 * @example
 * new Elysia()
 *     .state('counter', 1)
 *     .derive(({ store }) => ({
 *         user: getCurrentUser(store)
 *     }))
 *     .get('/', ({ user }) => `Hello ${user.name}`)
 */
```

**Type Flow:**
- Input: `Context` with full schema + singleton + ephemeral + volatile decorators
- Output: `Derivative` object added to `Volatile['derive']`
- Returned type is subtracted from Elysia return (excludes error response types)
- Can return error response to skip main handler

---

## 7. Decorate - Singleton Decorator Addition

**File:** `/src/index.ts:7189-7290`

```typescript
decorate<const Name extends string, Value>(
	name: Name,
	value: Value
): Elysia<
	BasePath,
	{
		decorator: Singleton['decorator'] & {
			[name in Name]: Value
		}
		store: Singleton['store']
		derive: Singleton['derive']
		resolve: Singleton['resolve']
	},
	Definitions,
	Metadata,
	Routes,
	Ephemeral,
	Volatile
>

/**
 * Define custom method to `Context` accessible for all handlers.
 *
 * @example
 * new Elysia()
 *     .decorate('getDate', () => Date.now())
 *     .get('/', ({ getDate }) => getDate())
 */
decorate<NewDecorators extends Record<string, unknown>>(
	decorators: NewDecorators
): Elysia<
	BasePath,
	{
		decorator: Singleton['decorator'] & NewDecorators
		store: Singleton['store']
		derive: Singleton['derive']
		resolve: Singleton['resolve']
	},
	Definitions,
	Metadata,
	Routes,
	Ephemeral,
	Volatile
>

decorate<NewDecorators extends Record<string, unknown>>(
	mapper: (decorators: Singleton['decorator']) => NewDecorators
): Elysia<
	BasePath,
	{
		decorator: NewDecorators
		store: Singleton['store']
		derive: Singleton['derive']
		resolve: Singleton['resolve']
	},
	Definitions,
	Metadata,
	Routes,
	Ephemeral,
	Volatile
>

/**
 * Define custom method to `Context` accessible for all handlers.
 *
 * @example
 * new Elysia()
 *     .decorate({ as: 'override' }, 'getDate', () => Date.now())
 *     .get('/', ({ getDate }) => getDate())
 */
decorate<
	const Type extends ContextAppendType,
	const Name extends string,
	Value
>(
	options: { as: Type },
	name: Name,
	value: Value
): Elysia<
	BasePath,
	{
		decorator: Type extends 'override'
			? Reconcile<
					Singleton['decorator'],
					{
						[name in Name]: Value
					},
					true
				>
			: Singleton['decorator'] & {
					[name in Name]: Value
				}
		...
	}
>
```

**Overload Patterns:**
- Single-argument: `value` | `record` | `function`
- Two-argument: `name, value` combos
- Options variant: `{ as: 'override' | 'append' }, name, value`

---

## 8. Plugin System - `.use()` Pattern

**File:** `/src/index.ts:4768-4850`

```typescript
use<const NewElysia extends AnyElysia>(
	instance: MaybePromise<NewElysia>
): Elysia<
	BasePath,
	{
		decorator: Singleton['decorator'] &
			NewElysia['~Singleton']['decorator']
		store: Prettify<
			Singleton['store'] & NewElysia['~Singleton']['store']
		>
		derive: Singleton['derive'] & NewElysia['~Singleton']['derive']
		resolve: Singleton['resolve'] & NewElysia['~Singleton']['resolve']
	},
	Definitions & NewElysia['~Definitions'],
	Metadata & NewElysia['~Metadata'],
	BasePath extends ``
		? Routes & NewElysia['~Routes']
		: Routes & CreateEden<BasePath, NewElysia['~Routes']>,
	Ephemeral,
	Volatile & NewElysia['~Ephemeral']
>

// Example from test
const yay = async () => {
	await Bun.sleep(2)
	return new Elysia({ name: 'yay' }).get('/yay', 'yay')
}

const wrapper = new Elysia({ name: 'wrapper' }).use(yay())
const app = new Elysia().use(wrapper)

await app.modules
```

**Plugin Type Merging:**
- Merges `Singleton` (decorator, store, derive, resolve) from child
- Merges `Definitions` (typebox schemas, errors)
- Merges `Routes` recursively with `CreateEden` for path nesting
- Supports async/lazy plugin loading via `Promise<Elysia>`
- Automatically awaits `.modules` for module loading

---

## 9. Lifecycle Hooks: onTransform, onBeforeHandle, onError

**File:** `/src/index.ts:1464-1543 (onTransform), 1936-2015 (onBeforeHandle), 3148-3225 (onError)`

```typescript
onTransform<const Schema extends RouteSchema>(
	handler: MaybeArray<
		TransformHandler<
			UnknownRouteSchema<ResolvePath<BasePath>>,
			{
				decorator: Singleton['decorator']
				store: Singleton['store']
				derive: Singleton['derive'] &
					Ephemeral['derive'] &
					Volatile['derive']
				resolve: {}
			}
		>
	>
): this

onTransform<const Schema extends RouteSchema, const Type extends LifeCycleType>(
	options: { as: Type },
	handler: MaybeArray<TransformHandler<...>>
): this

onBeforeHandle<
	const Schema extends RouteSchema,
	const Handler extends OptionalHandler<
		MergeSchema<
			Schema,
			MergeSchema<
				Volatile['schema'],
				MergeSchema<Ephemeral['schema'], Metadata['schema']>
			>,
			BasePath
		> & Metadata['standaloneSchema'] &
			Ephemeral['standaloneSchema'] &
			Volatile['standaloneSchema'],
		Singleton & {
			derive: Ephemeral['derive'] & Volatile['derive']
			resolve: Ephemeral['resolve'] & Volatile['resolve']
		}
	>
>(
	handler: Handler
): Elysia<
	BasePath,
	Singleton,
	Definitions,
	Metadata,
	Routes,
	Ephemeral,
	{
		derive: Volatile['derive']
		resolve: Volatile['resolve']
		schema: Volatile['schema']
		standaloneSchema: Volatile['standaloneSchema']
		response: UnionResponseStatus<
			Volatile['response'],
			ElysiaHandlerToResponseSchema<Handler>
		>
	}
>

onError<
	const Schema extends RouteSchema,
	const Handler extends ErrorHandler<
		Definitions['error'],
		MergeSchema<
			Schema,
			MergeSchema<
				Volatile['schema'],
				MergeSchema<Ephemeral['schema'], Metadata['schema']>
			>
		> & Metadata['standaloneSchema'] &
			Ephemeral['standaloneSchema'] &
			Volatile['standaloneSchema'],
		Singleton,
		Ephemeral,
		Volatile
	>
>(
	handler: Handler
): Elysia<...>

// Example usage
new Elysia()
	.state('counter', 0)
	.onTransform(({ store }) => {
		store.counter++
	})
	.get('/', ({ store: { counter } }) => counter, {
		transform: [
			({ store }) => { store.counter++ },
			({ store }) => { store.counter++ }
		]
	})
	.listen(3000)
```

**Hook Execution Order:**
1. `onTransform` - pre-validation, mutate params/body
2. `onBeforeHandle` - post-validation, pre-handler (can skip handler)
3. Route handler
4. `onError` - exception catch-all

---

## 10. WebSocket Route Declaration

**File:** `/example/websocket.ts:1-26`

```typescript
import { Elysia } from '../src'

const app = new Elysia()
	.state('start', 'here')
	.ws('/ws', {
		open(ws) {
			ws.subscribe('asdf')
			console.log('Open Connection:', ws.id)
		},
		close(ws) {
			console.log('Closed Connection:', ws.id)
		},
		message(ws, message) {
			ws.publish('asdf', message)
			ws.send(message)
		}
	})
	.get('/publish/:publish', ({ params: { publish: text } }) => {
		app.server!.publish('asdf', text)
		return text
	})
	.listen(3000, (server) => {
		console.log(`http://${server.hostname}:${server.port}`)
	})
```

**WS Handlers:**
- `open(ws)` - connection established
- `message(ws, message)` - message received
- `close(ws)` - connection closed
- `ws.subscribe(topic)` - pub/sub topic join
- `ws.publish(topic, msg)` - broadcast to topic
- `app.server.publish()` - cross-connection broadcast

---

## 11. Eden Client Type-Safe Integration

**File:** `/src/types.ts:2130-2152`

```typescript
type _CreateEden<
	Path extends string,
	Property extends Record<string, unknown> = {}
> = Path extends `${infer Start}/${infer Rest}`
	? {
			[x in Start]: _CreateEden<Rest, Property>
		}
	: Path extends ''
		? Property
		: {
				[x in Path]: Property
			}

type RemoveStartingSlash<T> = T extends `/${infer Rest}` ? Rest : T

export type CreateEden<
	Path extends string,
	Property extends Record<string, unknown> = {}
> = Path extends `/${infer Rest}`
	? _CreateEden<Rest, Property>
	: Path extends '' | '/'
		? Property
		: _CreateEden<Path, Property>
```

**Eden Type Magic:**
- Recursively builds nested object type from path string (e.g., `/api/users/:id`)
- Maps paths to route handlers with full type safety
- Applied in `.use()` when BasePath is set (returns `CreateEden<BasePath, Routes>`)
- Enables IDE autocomplete on nested paths: `client.api.users[id].get()`

---

## Summary

**Core Architecture:**
1. **Class System**: 7 generic parameters (BasePath, Singleton, Definitions, Metadata, Routes, Ephemeral, Volatile) chain types through fluent API
2. **Type Inference**: Path parsing → schema merging → decorator intersection → handler type narrowing
3. **Sucrose Analyzer**: Character-code parsing extracts handler params at compile time for code injection
4. **Lifecycle**: Transform → BeforeHandle → Handler → Error (per-request execution flow)
5. **Context Augmentation**: `derive()` (per-request) vs `decorate()` (singleton) primitives
6. **Plugin System**: Merges Singleton/Definitions/Routes from child Elysia instances
7. **Eden Types**: Recursive type mapping creates nested client objects matching server routes
8. **WebSocket**: Native `.ws()` with pub/sub topic support
9. **Schema Validation**: Typebox integration with status-based response schemas

**Key Design Patterns:**
- Branded type params (`const in out`) for type flow without runtime cost
- Virtual properties (`~Prefix`, etc) for type-only bookkeeping
- Sucrose "magic" leverages stringified functions for static analysis
- Merge strategy unions schemas at each scope (metadata → ephemeral → volatile)
- CreateEden builds IDE-complete client types from routes

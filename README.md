# Passport

Passport is a Swift library for defining database tables, type-safe SQL queries, and migrations in one place, then compiling them into dialect-specific SQL and generated client code.

You declare tables and queries as Swift types. Passport validates them, builds PostgreSQL SQL (including CTEs for nested queries), and can emit typed Go helpers via `GoSQLAdapter`.

## Status / WIP

Passport is early and actively evolving. Query definition, PostgreSQL SQL compilation, and nested CTE queries are the most usable parts today. Several areas exist in the API but are incomplete:

| Area | Status |
| --- | --- |
| **Migrations** | **WIP.** You can declare `Migration` steps (`CreateTableMigrationStep`, `CreateColumnMigrationStep`) and Passport compiles them to SQL internally, but the `Schema` entrypoint does not write migration output — adapters only receive built queries. Step kinds are limited to create-table and add-column. Column defaults (`DefaultValue`) are stubbed on `Column` and not emitted in SQL yet. |
| **Adapters / codegen** | **WIP.** Only `GoSQLAdapter` ships. It generates Go `database/sql` helpers for queries (result structs + functions), not table models or migration files. Other languages are not implemented. |
| **Dialects** | **WIP beyond Postgres.** `PostgreSQL` is the only dialect. The `Dialect` protocol is the extension point for more. |
| **Query predicates & expressions** | **Partial.** Filters support `==`, null checks, and `Condition.all` / `Condition.one`. SQL functions (`lower` / `upper` / arithmetic) exist in the dialect layer (`QueryFunction`) without ergonomic builder helpers yet. Broader operators (`>`, `LIKE`, `IN`, etc.) are not there. |
| **Column types** | **Partial.** Common builders (`.string()`, `.uuid()`, numbers, dates) are ready. `.blob` is supported by the Postgres dialect and Go adapter, but there is no `Column.blob()` helper yet. |
| **Tests & tooling** | **WIP.** There is no package test target yet. CLI flags on `Schema` are commented out / unused. |

What works well right now: defining tables and queries in Swift, joins, nested insert/update-as-CTE selects, argument typing, return-shape inference (including join optionality), and generating Go query wrappers via `GoSQLAdapter`. See [`Sources/PassportDemo`](Sources/PassportDemo).

## Requirements

- Swift 6.2+
- macOS 14+

## Installation

Add Passport to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/jacksonzamorano/passport.git", branch: "master")
]
```

Then depend on the `Passport` product:

```swift
.target(
    name: "MySchema",
    dependencies: [
        .product(name: "Passport", package: "passport")
    ]
)
```

## Quick start

Define a table, a query, and a schema entrypoint that writes Go code:

```swift
import Passport

struct User: Table {
    enum Key: String, TableKey {
        case id, email
    }

    static let tableName = "users"

    static func column(_ key: Key) -> Column {
        switch key {
        case .id: .uuid().required()
        case .email: .string().required()
        }
    }
}

struct SelectUserByEmail: Select {
    enum ReturnType: String, ProjectionKey {
        case id, email
    }

    func select(query: SelectQueryBuilder<ReturnType>) {
        let users = query.from(User.self)
        let email = query.argument("email", dataType: .string)

        query.filter {
            users[.email] == email
        }

        query.selectAll(from: users)
    }
}

Schema(dialect: PostgreSQL()) {
    User()
    SelectUserByEmail()

    Adapter(
        GoSQLAdapter(packageName: "main"),
        generateInto: .gitRoot(appending: ["generated", "go"])
    )
}
```

Run your schema target:

```bash
swift run MySchema
```

Passport validates the schema, compiles queries to SQL, and writes generated files through any adapters you registered.

A fuller working example lives in [`Sources/PassportDemo`](Sources/PassportDemo). Run it with:

```bash
swift run PassportDemo
```

## Keys

Keys are string-backed enums that name columns and query result fields. They are how Passport keeps table definitions, projections, and generated types aligned.

### `TableKey`

Every `Table` has an associated `Key` that conforms to `TableKey` (and therefore `ProjectionKey`). Use it for:

- Declaring columns via `static func column(_ key: Key) -> Column`
- Addressing columns on table references: `users[.email]`
- Returning every column from a table when `ReturnType == Table.Key`

```swift
struct Post: Table {
    enum Key: String, TableKey {
        case id, text, userID, createdDate
    }

    static let tableName = "posts"

    static func column(_ key: Key) -> Column {
        switch key {
        case .id: .uuid().required()
        case .text: .string()
        case .userID: .uuid().required().foreignKey(User.self, column: .id)
        case .createdDate: .timezonedDate().required()
        }
    }
}
```

### `ProjectionKey`

Queries declare a `ReturnType: ProjectionKey`. Each case becomes a selected / returned column alias (and a field on generated result types).

You can reuse a table’s `Key` as the return shape, or define a narrower projection:

```swift
enum PostSummary: String, ProjectionKey {
    case text, userEmail
}
```

Passport validates that every projection case is bound exactly once.

## Tables and columns

Tables conform to `Table` and list columns through their `Key`:

```swift
struct UserProfile: Table {
    enum Key: String, TableKey {
        case id, userID, username
    }

    static let tableName = "user_profiles"

    static func column(_ key: Key) -> Column {
        switch key {
        case .id: .uuid().required()
        case .userID: .uuid().required().foreignKey(User.self, column: .id)
        case .username: .string().required()
        }
    }
}
```

### Column builders

| Builder | Data type |
| --- | --- |
| `.string()` | `.string` |
| `.uuid()` | `.uuid` |
| `.int32()` / `.int64()` | `.integer32` / `.integer64` |
| `.float32()` / `.float64()` | `.float32` / `.float64` |
| `.date()` | `.date` |
| `.timezonedDate()` | `.dateWithTimezone` |

### Column modifiers

Columns are nullable by default. Chain modifiers as needed:

```swift
.string().required()
.uuid().nullable()
.uuid().required().foreignKey(User.self, column: .id)
```

`foreignKey(_:column:)` records a SQL `REFERENCES` constraint for migrations (see [Status / WIP](#status--wip) — migration output is not written yet).

## Queries

Queries are types conforming to `Select`, `Insert`, `Update`, or `Delete`. Register instances in `Schema { ... }`. The type name becomes the compiled query name (and generated function name).

### Select

```swift
struct SelectPostsQuery: Select {
    enum ReturnType: String, ProjectionKey {
        case text, userEmail
    }

    func select(query: SelectQueryBuilder<ReturnType>) {
        let posts = query.from(Post.self, as: "posts")

        let users = query.join(foreign: User.self, as: "user", kind: .inner) { user in
            user[.id] == posts[.userID]
        }

        let email = query.argument("email", dataType: .string)
        query.filter {
            users[.email] == email
        }

        query.limit(10)
        query.sort(posts[.createdDate], direction: .descending)

        query.select(posts[.text], as: .text)
        query.select(users[.email], as: .userEmail)
    }
}
```

Supported join kinds: `.inner`, `.left`, `.right`. Left joins mark selected join columns as optional in the return shape.

### Insert

```swift
struct InsertPostQuery: Insert {
    typealias ReturnType = Post.Key

    func insert(query: InsertQueryBuilder<ReturnType>) {
        let posts = query.into(Post.self, as: "posts")
        let text = query.argument("text", dataType: .string)

        query.insert(posts[.text], value: text)
        query.returnAll(posts)
    }
}
```

Use `insertNull(_:)` to insert an explicit `NULL`.

### Update

```swift
struct UpdateEmail: Update {
    typealias ReturnType = User.Key

    func update(query: UpdateQueryBuilder<User.Key>) {
        let users = query.update(User.self, as: "users")
        let email = query.argument("email", dataType: .string)

        query.set(users[.email], value: email)
        query.returnAll(from: users)
    }
}
```

Use `unset(_:)` to set a column to `NULL`.

### Delete

```swift
struct DeletePost: Delete {
    typealias ReturnType = Post.Key

    func delete(query: DeleteQueryBuilder<Post.Key>) {
        let posts = query.from(Post.self)
        let postID = query.argument("postID", dataType: .uuid)

        query.filter {
            posts[.id] == postID
        }

        query.returnAll(from: posts)
    }
}
```

### Arguments and filters

Declare parameters with `query.argument(_:dataType:optional:)`:

```swift
let email = query.argument("email", dataType: .string)
let token = query.argument("token", dataType: .string, optional: true)
```

Compare values with `==`, and test nullability with `.isNull()` / `.notNull()`:

```swift
query.filter {
    payments[.verifiedDate].isNull()
}
```

Combine predicates with `Condition.all(...)` (AND) or `Condition.one(...)` (OR).

## Nested queries

Passport can nest an insert or update inside a select by embedding another query type and using it as the `from` source. The nested query becomes a CTE; its returned columns are available on the outer query.

This is useful when a write should return enriched rows (for example, joining related tables after an insert).

### Nested insert as a CTE

Embed an `Insert` as a nested struct, then `from` it in the outer `Select`:

```swift
enum FullPayment: String, ProjectionKey {
    case id, fromUserEmail, toUserEmail, amount, verifiedDate
}

struct InsertPayment: Select {
    struct _Insert: Insert {
        typealias ReturnType = Payment.Key

        func insert(query: InsertQueryBuilder<Payment.Key>) {
            let into = query.into(Payment.self)

            let fromUserID = query.argument("fromUserID", dataType: .uuid)
            let toUserID = query.argument("toUserID", dataType: .uuid)
            let amount = query.argument("amount", dataType: .float64)

            query.insert(into[.fromUserID], value: fromUserID)
            query.insert(into[.toUserID], value: toUserID)
            query.insert(into[.amount], value: amount)
            query.returnAll(into)
        }
    }

    func select(query: SelectQueryBuilder<FullPayment>) {
        let insert = query.from(_Insert())

        let fromUser = query.join(foreign: User.self, as: "fromUser", kind: .inner) { fromUser in
            fromUser[.id] == insert[.fromUserID]
        }
        let toUser = query.join(foreign: User.self, as: "toUser", kind: .inner) { toUser in
            toUser[.id] == insert[.toUserID]
        }

        query.resultTypeName("InsertedPayment")
        query.select(insert[.id], as: .id)
        query.select(insert[.amount], as: .amount)
        query.select(insert[.verifiedDate], as: .verifiedDate)
        query.select(fromUser[.email], as: .fromUserEmail)
        query.select(toUser[.email], as: .toUserEmail)
    }
}
```

Compiled SQL looks like:

```sql
WITH _Insert AS (
  INSERT INTO payments ... RETURNING ...
)
SELECT ... FROM _Insert AS _Insert
INNER JOIN users AS fromUser ON ...
INNER JOIN users AS toUser ON ...
```

Arguments declared on the nested query bubble up to the outer generated function.

### Nested update

The same pattern works with `Update`:

```swift
struct UnverifyPayment: Select {
    struct Modification: Update {
        func update(query: UpdateQueryBuilder<Payment.Key>) {
            let paymentID = query.argument("paymentID", dataType: .uuid)
            let payment = query.update(Payment.self)

            query.filter {
                paymentID == payment[.id]
            }
            query.unset(payment[.verifiedDate])
            query.returnAll(from: payment)
        }
    }

    func select(query: SelectQueryBuilder<FullPayment>) {
        let result = query.from(Modification())

        let fromUser = query.join(foreign: User.self, as: "fromUser", kind: .inner) { fromUser in
            fromUser[.id] == result[.fromUserID]
        }
        let toUser = query.join(foreign: User.self, as: "toUser", kind: .inner) { toUser in
            toUser[.id] == result[.toUserID]
        }

        query.select(result[.id], as: .id)
        query.select(result[.amount], as: .amount)
        query.select(result[.verifiedDate], as: .verifiedDate)
        query.select(fromUser[.email], as: .fromUserEmail)
        query.select(toUser[.email], as: .toUserEmail)
        query.resultTypeName("UnverifiedPayment")
    }
}
```

### Reusing a top-level query

Nested queries do not have to be private nested types. You can also pass an existing query value into `from`:

```swift
struct InsertGetPostWithEmail: Select {
    enum ReturnType: String, ProjectionKey {
        case text, userEmail
    }

    func select(query: SelectQueryBuilder<ReturnType>) {
        let result = query.from(InsertPostQuery(), as: "result")
        let users = query.join(foreign: User.self, as: "user", kind: .inner) { user in
            user[.id] == result[.userID]
        }

        query.select(users[.email], as: .userEmail)
        query.select(result[.text], as: .text)
    }
}
```

You can also attach additional CTEs with `query.with(_:as:)` and join them via `query.join(cte:as:kind:_)`.

## Convenience features

These helpers cut down boilerplate without changing the underlying model.

| Feature | What it does |
| --- | --- |
| `selectAll(from:)` | Projects every case of `ReturnType` from a table when `ReturnType == Table.Key` |
| `returnAll` / `returnAll(from:)` | Returns every table column from insert, update, or delete |
| `resultTypeName(_:)` | Overrides the generated result type name (default is `"\(QueryName)Result"`) |
| `argument(_:dataType:optional:)` | Declares a typed query parameter |
| `unset(_:)` / `insertNull(_:)` | Write `NULL` on update / insert |
| `.isNull()` / `.notNull()` | Null checks in filters |
| `.foreignKey(_:column:)` | Declares FK relationships for migrations |
| Join optionality | Left/right joins adjust optional return types automatically |

Example using `selectAll` and a null filter:

```swift
struct GetUnverifiedPayments: Select {
    func select(query: SelectQueryBuilder<Payment.Key>) {
        let payments = query.from(Payment.self)
        query.filter {
            payments[.verifiedDate].isNull()
        }
        query.selectAll(from: payments)
    }
}
```

## Migrations

> **WIP** — Migration steps compile to SQL, but Passport does not yet emit or write that SQL through adapters. Treat this API as experimental.

Migrations are ordered steps inside a `Migration` builder:

```swift
Migration {
    CreateTableMigrationStep(User.self)
    CreateTableMigrationStep(Post.self)
    CreateColumnMigrationStep(Post.self, column: .text)
}
```

Today only these step kinds exist:

- `CreateTableMigrationStep` — `CREATE TABLE` from the table’s keys and columns
- `CreateColumnMigrationStep` — `ALTER TABLE ... ADD COLUMN`

There is no drop/rename/index support yet, and compiled migration SQL is not passed to adapters (the `Schema` entrypoint only hands built queries to `AdapterBuilder.buildQuery`).

## Schema and adapters

`Schema(dialect:)` is the entrypoint. Put tables, queries, migrations, and adapters in the builder:

```swift
Schema(dialect: PostgreSQL()) {
    User()
    Post()

    SelectPostsQuery()
    InsertPayment()

    Migration {
        CreateTableMigrationStep(User.self)
        CreateTableMigrationStep(Post.self)
    }

    Adapter(
        GoSQLAdapter(packageName: "main"),
        generateInto: .gitRoot(appending: ["generated", "go"])
    )
}
```

### Dialects

Today Passport ships `PostgreSQL`, which compiles queries and migration steps to PostgreSQL SQL. Additional dialects are not implemented yet.

### Adapters

> **WIP** — Code generation is early. Only Go query helpers are generated.

Adapters turn compiled queries into language-specific files. The `AdapterBuilder` protocol currently exposes `buildQuery` only (no migration hook).

`GoSQLAdapter` writes Go structs and `database/sql` functions into the configured directory (for example `generated/go/model.go`), then runs `gofmt`. It does not generate table models or migration SQL files.

Output locations:

- `.gitRoot(appending: [...])` — walk up to the nearest `.git` directory, then append path components
- `.currentDirectory(appending: [...])` — relative to the process working directory

Implement `AdapterBuilder` to add other languages once you need them.

## Project layout

```
Passport/
├── Sources/
│   ├── Passport/          # Library
│   └── PassportDemo/      # End-to-end example schema
├── Package.swift
└── generated/             # Adapter output (e.g. Go)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

MIT. See [LICENSE](LICENSE).

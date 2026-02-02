# ``Passport``

Full-stack across your stack.

Passport is a Swift-based schema definition and code generation tool that keeps your backend and frontend in sync. Define your data models, database tables, queries, and API routes once in Swift, then generate type-safe code and SQL for multiple languages.

## Overview

Passport provides a single source of truth for your application's data layer. Using Swift macros, you define models, records, enums, and routes, which Passport then uses to generate:

- **SQL schemas** for PostgreSQL databases
- **Type-safe code** in Go, TypeScript, and Swift
- **Query builders** for SELECT, INSERT, UPDATE, and DELETE operations
- **API route definitions** consistent across all target languages

### Quick Example

```swift
@Record(type: .table("users"))
struct User {
    let id = DEFAULT_ID_FIELD
    let name = Field(.string)
    let email = Field(.string)

    static let selectById = select(with: SelectByIdArgs.self) { query in
        query.filter("\(\User.id) = \(\.userId)")
        query.one()
    }

    @Argument
    struct SelectByIdArgs {
        let userId: DataType = .int64
    }
}

let schema = Schema("MyApp") {
    User.self
} routes: {
    RouteGroup(root: "/users") {
        Route("getUser", path: "/:id")
    }
}
```

## Topics

### Getting Started

- <doc:GettingStarted>
- <doc:DefiningModels>
- <doc:DefiningRecords>
- <doc:WorkingWithQueries>
- <doc:DefiningRoutes>

### Core Concepts

#### Models and Records
Define your data structures using Swift macros.

- ``Model()``
- ``Model``
- ``Record(type:)``
- ``Record``
- ``Enum``

#### Fields and Types
Build type-safe field definitions.

- ``Field``
- ``DataType``

#### Arguments
Create type-safe query parameters.

- ``Argument()``
- ``QueryArguments``

#### Routes
Define API endpoints consistently across languages.

- ``Route``
- ``RouteGroup``
- ``RouteMethod``
- ``Routeable``

### Schema Building

Organize and build your schema for code generation.

- ``Schema``
- ``SchemaBuilder``
- ``SchemaCompatible``
- ``SchemaEntity``

### Code Generation

#### Builders
Generate code and SQL from your schema.

- ``CodeBuilder``
- ``CodeBuilderConfiguration``
- ``SQLBuilder``

#### Languages
Generate code for different programming languages.

- ``Language``
- ``Go``
- ``TypeScript``
- ``Swift``

#### Dialects
Generate SQL for different database systems.

- ``Dialect``
- ``Postgres``

### Advanced Topics

- <doc:CustomLanguages>
- <doc:CustomDialects>
- <doc:ExtendingPassport>

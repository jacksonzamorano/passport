# Passport

**Full-stack across your stack.**

Passport is a Swift-based schema definition and code generation tool that keeps your backend and frontend in sync. Define your data models, database tables, queries, and API routes once in Swift, then generate type-safe code and SQL for multiple languages.

## What is Passport?

Passport lets you define your application's data layer in a single source of truth using Swift macros. It then generates:

- **SQL schemas** for your database (PostgreSQL support included)
- **Type-safe code** in Go, TypeScript, and Swift
- **Query builders** for common database operations (SELECT, INSERT, UPDATE, DELETE)
- **Type-safe query arguments** with compile-time validation
- **API route definitions** for consistent endpoints across your stack

## Why Passport?

**Problem**: In traditional full-stack development, you maintain separate type definitions for:
- Database schemas (SQL DDL)
- Backend models (Go structs, TypeScript interfaces, etc.)
- Frontend types (TypeScript interfaces)
- API request/response types

When your data model changes, you must update all of these manually, leading to inconsistencies and runtime errors.

**Solution**: Passport provides a single source of truth. Define your schema once in Swift, and automatically generate:
- Database migration scripts
- Type-safe models in multiple languages
- Query definitions with parameter validation
- Consistent types across your entire stack

## Quick Start

### 1. Define Your Schema

Define a database table with queries:

```swift
@Record(type: .table("users"))
struct User {
    let id = DEFAULT_ID_FIELD
    let name = Field(.string)
    let archived = Field(.bool)
    let status = Field(.value(UserStatus.self))

    // SELECT query with arguments
    static let selectById = select(with: SelectByIdArgs.self) { query in
        query.filter("\(\User.id) = \(\.userId)")
        query.filter("\(\User.archived) = false")
        query.one()
    }

    // SELECT query returning multiple results
    static let selectAll = select(with: NoArguments.self) { query in
        query.filter("\(\User.status) = \(UserStatus.active)")
        query.many()
    }

    // INSERT query
    static let insertUser = insert(\.name, \.archived)

    // UPDATE query
    static let updateName = update(with: UpdateNameArgs.self) { query in
        query.set("\(\User.name) = \(\UpdateNameArgs.name)")
        query.filter("\(\User.id) = \(\.userId)")
        query.one()
    }

    @Argument
    struct SelectByIdArgs {
        let userId: DataType = .int64
    }

    @Argument
    struct UpdateNameArgs {
        let userId: DataType = .int64
        let name: DataType = .string
    }

    @Argument
    struct NoArguments { }
}

@Enum
enum UserStatus: String {
    case inactive, active, removedByAdmin
}
```

Define request/response models:

```swift
@Model
struct GetUserRequest {
    var userId = Field(.int64)
}

@Model
struct UserCreateDto {
    var name = Field(.string)
}
```

Define API routes:

```swift
func userRoutes() -> RouteGroup {
    return RouteGroup(root: "/users") {
        Route("getUsers", path: "/")
        Route("createUser", path: "/create", method: .post)
    }
}
```

### 2. Build and Export

Build your schema and export to multiple languages:

```swift
@main
struct SchemaBuilder {
    static func main() {
        let postgres = SQLBuilder(Postgres())

        let schema = Schema("MyApp") {
            User.self
            UserStatus.self
            GetUserRequest.self
            UserCreateDto.self
        } routes: {
            userRoutes()
        }
        .output(Go(sqlBuilder: postgres)) {
            CodeBuilderConfiguration(
                root: URL(filePath: "./generated/go"),
                generateRecords: .asRecords,
                generateRoutes: true
            )
        }
        .output(TypeScript(buildIndex: true)) {
            CodeBuilderConfiguration(
                root: URL(filePath: "./generated/typescript"),
                generateRoutes: true
            )
        }
        .output(Swift(targetedPlatform: .bits64, standardizePropertyNames: true)) {
            CodeBuilderConfiguration(
                root: URL(filePath: "./generated/swift"),
                generateRoutes: true
            )
        }

        try! schema.build()
    }
}
```

### 3. Run the Schema Builder

Execute your schema builder to generate all code:

```bash
swift run YourSchemaTarget
```

This will generate:
- **PostgreSQL schema** (tables, queries, types)
- **Go structs and functions** for models, records, and routes
- **TypeScript interfaces and types** for models, records, and routes
- **Swift types** for models, records, and routes

## Key Features

- **Single Source of Truth**: Define your schema once in Swift
- **Multi-Language Support**: Generate code for Go, TypeScript, and Swift
- **SQL Generation**: Create database schemas from your record definitions
- **Type Safety**: Compile-time validation of your data structures
- **Query Builder**: Define and generate type-safe database queries
- **Route Generation**: Define API routes that generate consistently across languages
- **Swift Macros**: Clean, declarative syntax using `@Model`, `@Record`, `@Enum`, and `@Argument`

## Core Concepts

### 1. Models

Models are simple data transfer objects (DTOs) used for API requests/responses. Use the `@Model` macro:

```swift
@Model
struct CreateUserRequest {
    var email = Field(.string)
    var name = Field(.string)
    var role = Field(.value(UserRole.self))
}
```

### 2. Records

Records represent database tables or views. Use the `@Record` macro and define queries:

```swift
@Record(type: .table("users"))
struct User {
    let id = DEFAULT_ID_FIELD  // Pre-configured primary key
    let email = Field(.string)
    let name = Field(.string)
    let role = Field(.value(UserRole.self))
    let createdAt = Field(.datetime)

    // Define queries with type-safe arguments
    static let selectByEmail = select(with: SelectByEmailArgs.self) { query in
        query.filter("\(\User.email) = \(\.email)")
        query.one()
    }

    static let selectAll = select(with: NoArguments.self) { query in
        query.many()
    }

    @Argument
    struct SelectByEmailArgs {
        let email: DataType = .string
    }

    @Argument
    struct NoArguments { }
}
```

### 3. Enums

Enums provide type-safe enumeration values for both database and generated code:

```swift
@Enum
enum UserRole: String {
    case admin
    case user
    case guest
}
```

### 4. Fields

Fields define the properties of models and records with type information:

```swift
// Simple field
var name = Field(.string)

// Optional field
var bio = Field(.optional(.string))

// Array field
var tags = Field(.array(.string))

// Enum field
var status = Field(.value(UserStatus.self))

// Model reference field
var user = Field(.model(User.self))

// Common field types
var id = Field(.int64)
var count = Field(.int32)
var price = Field(.double)
var isActive = Field(.bool)
var createdAt = Field(.datetime)
var uuid = Field(.uuid)
var data = Field(.bytes)
```

### 5. Queries

Define type-safe database queries using the query builder DSL:

```swift
// SELECT query returning a single result
static let selectById = select(with: SelectByIdArgs.self) { query in
    query.filter("\(\User.id) = \(\.userId)")
    query.filter("\(\User.archived) = false")
    query.one()
}

// SELECT query returning multiple results
static let selectActive = select(with: NoArguments.self) { query in
    query.filter("\(\User.archived) = false")
    query.many()
}

// INSERT query - specify which fields to insert
static let insertUser = insert(\.email, \.name, \.role)

// UPDATE query with filters
static let updateName = update(with: UpdateNameArgs.self) { query in
    query.set("\(\User.name) = \(\UpdateNameArgs.name)")
    query.filter("\(\User.id) = \(\.userId)")
    query.one()
}

// DELETE query
static let deleteUser = delete(with: DeleteUserArgs.self) { query in
    query.filter("\(\User.id) = \(\.userId)")
}
```

### 6. Routes

Define API routes that will be generated consistently across all target languages:

```swift
// Define a route group with a common prefix
func userRoutes() -> RouteGroup {
    return RouteGroup(root: "/users") {
        Route("getUsers", path: "/", method: .get)
        Route("getUserById", path: "/:id", method: .get)
        Route("createUser", path: "/create", method: .post)
        Route("updateUser", path: "/:id", method: .patch)
        Route("deleteUser", path: "/:id", method: .delete)
    }
}

// Nest route groups
func apiRoutes() -> RouteGroup {
    return RouteGroup(root: "/api/v1") {
        userRoutes()
        postRoutes()
        commentRoutes()
    }
}

// Add routes to your schema
let schema = Schema("MyApp") {
    // ... models and records
} routes: {
    apiRoutes()
}
```

Route methods available:
- `.get` - GET requests
- `.post` - POST requests
- `.patch` - PATCH requests
- `.put` - PUT requests
- `.delete` - DELETE requests

## Advanced Features

### Language-Specific Configuration

Customize code generation for each target language:

```swift
// Go configuration
let goConfig = GoConfiguration { cfg in
    cfg.packageName = "myapp"
}

schema.output(Go(sqlBuilder: postgres, config: goConfig)) {
    CodeBuilderConfiguration(
        root: URL(filePath: "./generated/go"),
        generateRecords: .asRecords,  // or .asInterfaces
        generateRoutes: true
    )
}

// TypeScript configuration
schema.output(TypeScript(buildIndex: true)) {
    CodeBuilderConfiguration(
        root: URL(filePath: "./generated/typescript"),
        generateRoutes: true
    )
}

// Swift configuration
schema.output(Swift(targetedPlatform: .bits64, standardizePropertyNames: true)) {
    CodeBuilderConfiguration(
        root: URL(filePath: "./generated/swift"),
        generateRoutes: true
    )
}
```

### Custom SQL Dialects

Implement custom SQL dialects for other databases by conforming to the `Dialect` protocol:

```swift
class MySQL: Dialect {
    var terminator: String = ";"

    func convertType(_ type: DataType) throws -> String {
        switch type {
        case .int64:
            return "BIGINT"
        case .string:
            return "VARCHAR(255)"
        // ... implement other types
        default:
            throw SQLError.typeNotSupported(type)
        }
    }

    // Implement other required methods...
}

// Use in schema
let mysql = SQLBuilder(MySQL())
schema.output(Go(sqlBuilder: mysql)) { config }
```

### Custom Language Generators

Extend Passport to generate code for additional languages by conforming to the `Language` protocol:

```swift
struct Python: Language {
    func comment(for comment: String) -> String {
        return "# \(comment)"
    }

    func convert(type: DataType, inFile file: File) throws -> String {
        switch type {
        case .int64:
            return "int"
        case .string:
            return "str"
        case .bool:
            return "bool"
        // ... implement other types
        default:
            throw LanguageError.typeNotSupported(type)
        }
    }

    // Implement other required methods...
}
```

## Project Structure

When using Passport, a typical project structure might look like:

```
MyProject/
├── Package.swift
├── Sources/
│   ├── Schema/           # Your schema definitions
│   │   ├── Models/
│   │   │   ├── User.swift
│   │   │   └── Post.swift
│   │   ├── Enums/
│   │   │   └── UserRole.swift
│   │   └── Main.swift    # Schema build script
│   └── Generated/        # Output directory (gitignored)
│       ├── go/
│       ├── typescript/
│       └── swift/
├── database/
│   └── schema.sql        # Generated SQL
```

## API Reference

### Core Types

- **`Field`**: Represents a field/property in a model or record
- **`DataType`**: The type system (int32, int64, string, double, bool, datetime, uuid, bytes, array, optional, model, value)
- **`Schema`**: Groups models, records, enums, and routes for code generation
- **`Route`**: Represents an API endpoint with a path and HTTP method
- **`RouteGroup`**: Groups routes under a common path prefix

### Macros

- **`@Model`**: Marks a struct as a data transfer object (DTO)
- **`@Record(type:)`**: Marks a struct as a database record (table or view)
- **`@Enum`**: Marks an enum for inclusion in the schema
- **`@Argument`**: Marks a struct as type-safe query arguments

### Query Builders

- **`select(with:)`**: Builds SELECT queries with filters and result cardinality
- **`insert(...)`**: Builds INSERT queries for specified fields
- **`update(with:)`**: Builds UPDATE queries with SET and WHERE clauses
- **`delete(with:)`**: Builds DELETE queries with WHERE clauses

### Builders

- **`SQLBuilder`**: Generates SQL DDL and queries from a dialect
- **`CodeBuilder`**: Orchestrates code generation for a language
- **`CodeBuilderConfiguration`**: Configures output paths and generation options

### Languages

- **`Go(sqlBuilder:config:)`**: Go code generator with optional configuration
- **`TypeScript(buildIndex:)`**: TypeScript code generator with optional index file generation
- **`Swift(targetedPlatform:standardizePropertyNames:)`**: Swift code generator with platform targeting

### Dialects

- **`Postgres`**: PostgreSQL SQL dialect implementation

### Route Methods

- **`RouteMethod.get`**: HTTP GET
- **`RouteMethod.post`**: HTTP POST
- **`RouteMethod.patch`**: HTTP PATCH
- **`RouteMethod.put`**: HTTP PUT
- **`RouteMethod.delete`**: HTTP DELETE

## Documentation

For detailed API documentation, see the DocC documentation included in this package. Build the documentation with:

```bash
swift package generate-documentation
```

## Installation

### Requirements

- Swift 6.2+
- macOS 14+

### Add to Your Project

Add Passport to your Swift package dependencies in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/passport.git", from: "1.0.0")
]
```

Then add it as a dependency to your target:

```swift
targets: [
    .executableTarget(
        name: "MySchemaBuilder",
        dependencies: ["Passport"]
    )
]
```

### Create a Schema Builder

Create a new executable target in your project for building your schema:

```swift
// Sources/MySchemaBuilder/Main.swift
import Passport
import Foundation

@main
struct MySchemaBuilder {
    static func main() {
        // Define your schema here (see Quick Start above)
        let schema = Schema("MyApp") {
            // Your models and records
        } routes: {
            // Your routes
        }

        try! schema.build()
    }
}
```

### Run Your Schema Builder

```bash
swift run MySchemaBuilder
```

This will generate all your code in the configured output directories.

## Roadmap

Future features under consideration:

- [ ] MySQL dialect support
- [ ] SQLite dialect support
- [ ] Python code generator
- [ ] Rust code generator
- [ ] Java/Kotlin code generator
- [ ] Migration generation and versioning
- [ ] Schema diffing and change detection
- [ ] JOIN support in queries
- [ ] Aggregate functions (COUNT, SUM, AVG, etc.)
- [ ] Transactions and batch operations
- [ ] CLI tool for schema management

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for your changes
5. Ensure all tests pass (`swift test`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

Please ensure your code:
- Follows Swift best practices and conventions
- Includes appropriate documentation comments
- Includes tests for new functionality
- Maintains backwards compatibility when possible

For major changes, please open an issue first to discuss what you would like to change.

## License

This project is available under the MIT License. See the LICENSE file for more information.

---

**Built with Swift**

Passport is built using Swift macros and the Swift Package Manager. For more information about Swift macros, see the [Swift Evolution proposal SE-0382](https://github.com/apple/swift-evolution/blob/main/proposals/0382-expression-macros.md).

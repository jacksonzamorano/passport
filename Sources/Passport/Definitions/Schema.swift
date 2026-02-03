import Foundation

/// Finds the root directory of a Swift package by looking for Package.swift.
///
/// This utility function searches upward from the given file path to find
/// the directory containing Package.swift, which is typically the root of
/// a Swift package.
///
/// - Parameter url: The file path to start searching from (typically #filePath)
/// - Returns: The URL of the package root directory
///
/// ## Example
/// ```swift
/// let root = packageRoot(#filePath)
/// let outputPath = root.appending(path: "generated/go")
/// ```
public func packageRoot(_ url: String) -> URL {
    let fileManager = FileManager.default

    let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
    if fileManager.fileExists(atPath: cwd.appendingPathComponent("Package.swift").path) {
        return cwd
    }

    var url = URL(fileURLWithPath: "\(url)").deletingLastPathComponent()
    while url.path != "/" {
        let manifest = url.appendingPathComponent("Package.swift")
        if fileManager.fileExists(atPath: manifest.path) {
            return url
        }
        url.deleteLastPathComponent()
    }

    print("[Resolved root] \(url.path())")
    return url
}

struct SQLScriptBuilder {
    var builder: SQLBuilder
    var rootDirectory: URL
}

/// A schema groups models, records, enums, and routes for code generation.
///
/// `Schema` is the central organizing construct in Passport. It collects all your
/// type definitions and route definitions, then generates code for multiple target
/// languages and SQL for your database.
///
/// ## Creating a Schema
///
/// Use the result builder syntax to define your schema:
///
/// ```swift
/// let schema = Schema("MyApp") {
///     User.self
///     Post.self
///     Comment.self
///     UserStatus.self
/// } routes: {
///     RouteGroup(root: "/api/v1") {
///         userRoutes()
///         postRoutes()
///     }
/// }
/// ```
///
/// ## Generating Code
///
/// Chain `.output()` calls to specify target languages, then call `.build()`:
///
/// ```swift
/// try schema
///     .output(Go(sqlBuilder: postgres)) {
///         CodeBuilderConfiguration(root: URL(filePath: "./generated/go"))
///     }
///     .output(TypeScript(buildIndex: true)) {
///         CodeBuilderConfiguration(root: URL(filePath: "./generated/typescript"))
///     }
///     .build()
/// ```
public class Schema {
    /// The name of this schema, used in generated code
    var name: String

    /// All model types included in this schema
    var models: [any Model.Type]

    /// All record types (database tables) included in this schema
    var records: [any Record.Type]

    /// All enum types included in this schema
    var enums: [any Enum.Type]

    /// All routes included in this schema
    var routes: [ResolvedRoute]

    /// Code builders for each target language
    var builders: [CodeBuilder] = []
    
    /// SQL configurations registered
    var dialects: [SQLScriptBuilder] = []

    /// Creates a new schema with models, records, enums, and routes.
    ///
    /// - Parameters:
    ///   - name: A name for this schema (used in generated code)
    ///   - schema: A result builder closure that defines the types in this schema
    ///   - routes: A result builder closure that defines the API routes
    ///
    /// ## Example
    /// ```swift
    /// let schema = Schema("MyApp") {
    ///     User.self
    ///     Post.self
    ///     UserRole.self  // enum
    /// } routes: {
    ///     userRoutes()
    ///     postRoutes()
    /// }
    /// ```
    public init(
        _ name: String = "Schema",
        @SchemaBuilder _ schema: () -> SchemaBuilder.Result,
        @RouteableBuilder routes: () -> [any Routeable]
    ) {
        self.name = name
        let res = schema()
        models = res.models
        records = res.records
        enums = res.enums
        self.routes = routes().flatMap({ $0.routes(components: []) })
    }

    /// Adds a target language for code generation.
    ///
    /// Call this method one or more times to specify which languages to generate
    /// code for. Each call can include a configuration closure to customize the
    /// output directory and generation options.
    ///
    /// - Parameters:
    ///   - language: The language to generate code for (Go, TypeScript, Swift, etc.)
    ///   - configuration: An optional closure that returns a `CodeBuilderConfiguration`
    ///
    /// - Returns: Self, allowing for method chaining
    ///
    /// ## Example
    /// ```swift
    /// schema
    ///     .output(Go(sqlBuilder: postgres)) {
    ///         CodeBuilderConfiguration(
    ///             root: URL(filePath: "./generated/go"),
    ///             generateRecords: .asRecords,
    ///             generateRoutes: true
    ///         )
    ///     }
    ///     .output(TypeScript(buildIndex: true)) {
    ///         CodeBuilderConfiguration(
    ///             root: URL(filePath: "./generated/ts"),
    ///             generateRoutes: true
    ///         )
    ///     }
    /// ```
    public func output(_ language: any Language, configuration: (() -> CodeBuilderConfiguration)? = nil) -> Self {
        let config = configuration?() ?? .init()
        self.builders.append(.init(schemaName: self.name, language: language, configuration: config))
        return self
    }
    
    public func sql(_ sql: SQLBuilder, rootDirectory: URL) -> Self {
        self.dialects
            .append(
                SQLScriptBuilder(builder: sql, rootDirectory: rootDirectory)
            )
        return self
    }

    /// Builds the schema and generates all code and SQL.
    ///
    /// This method processes all models, records, enums, and routes, generating
    /// code files for each configured language and SQL schema files. Files are
    /// written to the directories specified in each language's configuration.
    ///
    /// - Throws: Any errors encountered during code generation or file writing
    ///
    /// ## Example
    /// ```swift
    /// do {
    ///     try schema.build()
    ///     print("Code generation completed successfully!")
    /// } catch {
    ///     print("Error generating code: \(error)")
    /// }
    /// ```
    public func build() throws {
        for dialect in dialects {
            let script = try dialect.builder.createScript(schema: self)
            try script
                .write(
                    to: dialect.rootDirectory.appending(path: "init.sql"),
                    atomically: true,
                    encoding: .utf8
                )
        }
        for builder in builders {
            try builder
                .build(
                    models: models,
                    records: records,
                    enms: enums,
                    routes: routes
                )
            try builder.finalize()
        }
    }
}


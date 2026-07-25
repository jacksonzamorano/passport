public struct BuiltQuery: Sendable {
    public let query: String
    public let arguments: [Argument]
    public let returnColumns: [ReturnedProperty]
    
    public struct ReturnedProperty: Sendable {
        public let name: String
        public let fullDataType: MaterializedDataType
    }
}

public struct BuiltMigration: Sendable {
    public struct Step: Sendable {
        public let name: String
        public let query: String
    }
    
    public var steps: [Step]
}

public struct BuildResult: Sendable {
    var queries: [BuiltQuery] = []
    var migrations: [BuiltMigration] = []
}

struct CompilationErrors: Error {
    struct CompilationError: Error {
        let error: DialectError
        let location: String
        
        public var description: String {
            "[D\(String(format: "%0", error.code.rawValue))] (\(location)): '\(error.context)' \(error.code.description)"
        }
    }
    
    var errors: [CompilationError] = []
    var hasErrors: Bool { !errors.isEmpty }
    
    mutating func add(_ err: DialectError, location: String) {
        self.errors.append(.init(error: err, location: location))
    }
    mutating func join(_ errors: CompilationErrors) {
        self.errors.append(contentsOf: errors.errors)
    }
}

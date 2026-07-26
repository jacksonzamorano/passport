import Foundation

public struct BuiltQuery: Sendable {
    public let queryName: String
    public let queryReturnTypeName: String
    public let query: String
    public let arguments: [Argument]
    public let returnColumns: [ReturnedProperty]
    
    public struct ReturnedProperty: Sendable {
        public let name: String
        public let fullDataType: DeclaredType
    }
    
    static func getReturnShape(query: Query, dialect: any Dialect) throws(DialectError) -> [ReturnedProperty] {
        var resolvedJoins = ReturnPrescense()
        switch query {
        case .select(let select):
            for join in select.joins {
                resolvedJoins.combine(join)
            }
        default: break
        }
        
        var returnedProperties: [ReturnedProperty] = []
        for projection in query.base.projections {
            var fullDataType = try projection.column.dataType(dialect: dialect)
            if case .column(let column) = projection.column,
               case .join(let joinID) = column.origin {
                if resolvedJoins.isOptional(joinID: joinID) {
                    fullDataType.optional = true
                }
            }
 
            returnedProperties.append(.init(
                name: projection.alias,
                fullDataType: fullDataType,
            ))
        }
        
        return returnedProperties
    }
}

struct ReturnPrescense {
    class Item {
        internal init(joinID: UUID? = nil, optional: Bool) {
            self.joinID = joinID
            self.optional = optional
        }
        
        let joinID: UUID?
        var optional: Bool
    }
    var rootOptional: Bool = false
    var joins: [Item] = []
    
    mutating func combine(_ join: Join) {
        switch join.kind {
        case .right:
            rootOptional = true
            for _join in joins { _join.optional = true }
        default:
            break
        }
        
        let selfOptional = switch join.kind {
        case .left: true
        default: false
        }
        joins.append(.init(joinID: join.id, optional: selfOptional))
    }
    
    func isOptional(joinID: UUID?) -> Bool {
        joins.first(where: { $0.joinID == joinID })!.optional
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
            "[\(error.code.codeString)] (\(location)): '\(error.context)' \(error.code.description)"
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

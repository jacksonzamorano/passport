import Foundation

enum QueryValidationError: Int, Error {
    case notAllProjectionsFulfilled,
         noTargetProvided,
         noOpCondition
    
    var codeString: String {
        String(format: "V%04d", rawValue+1)
    }
    
    var description: String {
        switch self {
        case .noTargetProvided: "A target wasn't provided for this query."
        case .notAllProjectionsFulfilled: "This query did not bind all projections to a column or expression."
        case .noOpCondition: "A filter with no predicate produces an empty condition."
        }
    }
}

public class BaseQueryProperties {
    public let identity: QueryIdentity
    public let arguments: [Argument]
    public let projections: [ReturnColumn]
    public let ctes: [CTE]
    
    public let target: SourceOrigin?
    
    private let expectedProjections: [String]
    
    init<ReturnType: ProjectionKey>(query: BaseQuery<ReturnType>) {
        self.identity = query.identity
        self.arguments = query.arguments
        self.projections = query.projections
        self.ctes = query.ctes
        self.target = query.target
        self.expectedProjections = ReturnType.allCases.map { $0.rawValue }
    }
    
    func validate() throws(QueryValidationError) {
        if Set(projections.map{ $0.alias }).count != expectedProjections.count {
            throw .notAllProjectionsFulfilled
        }
        if target == nil {
            throw .noTargetProvided
        }
        if case .cte(let target, _) = target, let cte = ctes.first(where: { $0.identifier == target }) {
            try cte.query.base.validate()
        }
    }
}

public struct ReturnColumn: Sendable {
    public let alias: String
    public let column: QueryValue
}

public class BaseQuery<ReturnType: ProjectionKey> {
    public var identity: QueryIdentity
    
    public var arguments: [Argument] = []
    public var projections: [ReturnColumn] = []
    public var relations: [Relation] = []
    public var ctes: [CTE] = []
    
    public var target: SourceOrigin?
    
    init(name: String) {
        self.identity = .init(name: name)
    }
    
    func target(_ origin: SourceOrigin) {
        self.target = origin
    }
    
    func bind<T: Table>(_ table: T.Type, as alias: String) -> TableSource<T> {
        let tableSource = TableSource(reference: .init(tableName: T.tableName, alias: alias), table: T.self)
        target(.table(tableSource.reference))
        return tableSource
    }
    
    func bind<Q: Insert>(_ query: Q, as alias: String) -> CTEReference<Q.ReturnType> {
        let identifier = CTEIdentifier(name: alias)
        ctes.append(CTE(identifier: identifier, query: .insert(.init(configuration: query))))
        target(.cte(identifier, alias: alias))
        return CTEReference(identifier: identifier, alias: alias)
    }
    
    func bind<K: ProjectionKey>(_ cte: CTESource<K>, as alias: String) -> CTEReference<K> {
        target(.cte(cte.identifier, alias: alias))
        return CTEReference(identifier: cte.identifier, alias: alias)
    }
    
    public func argument(_ name: String, dataType: DataType, optional: Bool = false) -> ArgumentReference {
        let argument = Argument(name: name, dataType: dataType, optional: optional)
        self.arguments.append(argument)
        return .init(name: argument.name, index: arguments.count - 1)
    }
    
    public func resultTypeName(_ name: String) {
        identity.queryReturnTypeName = name
    }
    
    func project(_ projectedValue: any IntoConditionValue, as alias: ReturnType) {
        self.projections.append(.init(alias: alias.rawValue, column: projectedValue.toConditionValue()))
    }
    
    public func with<T: Insert>(_ query: T, as alias: String) -> CTESource<T.ReturnType> {
        let identifier = CTEIdentifier(name: alias)
        
        let cte = CTE(identifier: identifier, query: .insert(.init(configuration: query)))
        ctes.append(cte)
        
        return .init(identifier: identifier)
    }
}

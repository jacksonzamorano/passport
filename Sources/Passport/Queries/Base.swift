import Foundation

enum QueryValidationError: Int, Error {
    case notAllProjectionsFulfilled,
         noTargetProvided,
         noOpCondition,
         noOpInsert,
         noOpUpdate
    
    var codeString: String {
        String(format: "V%04d", rawValue+1)
    }
    
    var description: String {
        switch self {
        case .noTargetProvided: "A target wasn't provided for this query."
        case .notAllProjectionsFulfilled: "This query did not bind all projections to a column or expression."
        case .noOpCondition: "A filter with no predicate produces an empty condition."
        case .noOpInsert: "This insert does nothing."
        case .noOpUpdate: "This update does nothing."
        }
    }
}

public class BaseQueryProperties {
    public let identity: QueryIdentity
    public let arguments: [Argument]
    public let projections: [ReturnColumn]
    public let ctes: [CTESource]
    
    public let target: SourceOrigin?
    public var targetGuaranteed: Bool = true

    private let expectedProjections: [String]
    
    init<ReturnType: ProjectionKey>(query: BaseQuery<ReturnType>) {
        self.identity = query.identity
        self.arguments = query.arguments
        self.projections = query.projections
        self.ctes = query.ctes
        self.target = query.target
        self.expectedProjections = ReturnType.allCases.map { $0.rawValue }
    }
    
    public subscript(_ key: String) -> ReturnColumn {
        projections.first(where: { $0.alias == key })!
    }
    
    func validate() throws(QueryValidationError) {
        if Set(projections.map{ $0.alias }).count != expectedProjections.count {
            throw .notAllProjectionsFulfilled
        }
        if target == nil {
            throw .noTargetProvided
        }
        if case .cte(let cteID) = target, let cte = ctes.first(where: { $0.identity.id == cteID.identity.id }) {
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
    public var ctes: [CTESource] = []
    
    public var target: SourceOrigin?
    
    init(name: String) {
        self.identity = .init(name: name)
    }
    
    func target(_ origin: SourceOrigin) {
        self.target = origin
    }
    
    func addSource(_ query: Query, name: String) -> CTESource {
        let cte = CTESource(name: name, query: query)
        ctes.append(cte)
        return cte
    }
    
    func bind<T: Table>(_ table: T.Type, as alias: String?) -> LocalTableReference<T> {
        let source = TableSource(alias: alias ?? table.tableName, table: table)
        target(.table(source))
        return .init(source)
    }
    
    func bind<Q: Select>(_ query: Q, as alias: String?) -> CTEReference<Q.ReturnType> {
        return bind(.select(.init(configuration: query)), as: alias)
    }
    
    func bind<Q: Insert>(_ query: Q, as alias: String?) -> CTEReference<Q.ReturnType> {
        return bind(.insert(.init(configuration: query)), as: alias)
    }
    
    func bind<Q: Update>(_ query: Q, as alias: String) -> CTEReference<Q.ReturnType> {
        return bind(.update(.init(configuration: query)), as: alias)
    }
    
    func bind<Keys: ProjectionKey>(_ query: Query, as alias: String?) -> CTEReference<Keys> {
        let source = addSource(query, name: alias ?? query.name)
        target(.cte(source))
        return .init(source, alias: alias ?? query.name)
    }

    public func argument(_ name: String, dataType: DataType, optional: Bool = false) -> ArgumentReference {
        let argument = Argument(name: name, dataType: .init(dataType: dataType, optional: optional))
        self.arguments.append(argument)
        return .init(name: argument.name, index: arguments.count - 1, dataType: dataType, optional: optional)
    }
    
    public func resultTypeName(_ name: String) {
        identity.queryReturnTypeName = name
    }
    
    func project(_ projectedValue: any IntoConditionValue, as alias: ReturnType) {
        self.projections.append(.init(alias: alias.rawValue, column: projectedValue.toConditionValue()))
    }
    
    public func with<Q: Select>(_ query: Q, as name: String) -> CTEPointer<Q.ReturnType> {
        let cte = addSource(.select(.init(configuration: query)), name: name)
        return .init(cte)
    }
    public func with<Q: Insert>(_ query: Q, as name: String) -> CTEPointer<Q.ReturnType> {
        let cte = addSource(.insert(.init(configuration: query)), name: name)
        return .init(cte)
    }
    public func with<Q: Update>(_ query: Q, as name: String) -> CTEPointer<Q.ReturnType> {
        let cte = addSource(.update(.init(configuration: query)), name: name)
        return .init(cte)
    }
}

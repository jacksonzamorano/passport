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
    
    func addSource<Q: Insert>(_ query: Q, name: String) -> CTESource {
        let cte = CTESource(name: name, query: .insert(.init(configuration: query)))
        ctes.append(cte)
        return cte
    }
    
    func bind<T: Table>(_ table: T.Type, as alias: String) -> LocalTableReference<T> {
        let source = TableSource(alias: alias, table: table)
        target(.table(source))
        return .init(source)
    }
    
    func bind<Q: Insert>(_ query: Q, as alias: String) -> CTEReference<Q.ReturnType> {
        let source = addSource(query, name: alias)
        target(.cte(source))
        return .init(source, alias: alias)
    }

    public func argument(_ name: String, dataType: DataType, optional: Bool = false) -> ArgumentReference {
        let argument = Argument(name: name, dataType: dataType, optional: optional)
        self.arguments.append(argument)
        return .init(name: argument.name, index: arguments.count - 1, dataType: dataType, optional: optional)
    }
    
    public func resultTypeName(_ name: String) {
        identity.queryReturnTypeName = name
    }
    
    func project(_ projectedValue: any IntoConditionValue, as alias: ReturnType) {
        self.projections.append(.init(alias: alias.rawValue, column: projectedValue.toConditionValue()))
    }
    
    public func with<T: Insert>(_ query: T, as name: String) -> CTEPointer<T.ReturnType> {
        let cte = addSource(query, name: name)
        return .init(cte)
    }
}

import Foundation

public class BaseQueryProperties {
    public let identity: QueryIdentity
    public let arguments: [Argument]
    public let projections: [ReturnColumn]
    public let ctes: [CTE]
    
    public let target: TableReference
    
    init<Base: Table, ReturnType: ProjectionKey>(query: BaseQuery<Base, ReturnType>, target: TableReference) {
        self.identity = query.identity
        self.arguments = query.arguments
        self.target = target
        self.projections = query.projections
        self.ctes = query.ctes
    }
}

public struct ReturnColumn: Sendable {
    public let alias: String
    public let column: QueryValue
}

public class BaseQuery<Base: Table, ReturnType: ProjectionKey> {
    internal var source: TableSource<Base>
    public var identity: QueryIdentity
    
    public var arguments: [Argument] = []
    public var projections: [ReturnColumn] = []
    public var relations: [Relation] = []
    public var ctes: [CTE] = []
    
    init(name: String, source: TableSource<Base>) {
        self.identity = .init(name: name)
        self.source = source
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
        let cte = CTE(alias: alias, query: .insert(.init(configuration: query)))
        ctes.append(cte)
        
        return .init(relationName: alias, alias: alias)
    }
}

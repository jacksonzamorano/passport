import Foundation

public class BaseQueryProperties {
    public let identity: QueryIdentity
    public let joins: [Join]
    public let arguments: [Argument]
    
    public let target: any Table.Type
    
    init<T>(query: Query<T>) {
        self.target = T.self
        self.identity = query.identity
        self.joins = query.joins
        self.arguments = query.arguments
    }
}

public class Query<Base: Table> {
    var identity: QueryIdentity
    
    var joins: [Join] = []
    var arguments: [Argument] = []
    
    init(name: String) {
        self.identity = .init(name: name)
    }
    
    public func argument(_ name: String, dataType: DataType, optional: Bool = false) -> ArgumentReference {
        let argument = Argument(name: name, dataType: dataType, optional: optional)
        self.arguments.append(argument)
        return .init(name: argument.name, index: arguments.count - 1)
    }
    
    public func resultTypeName(_ name: String) {
        identity.queryReturnTypeName = name
    }
    
    public func join<Foreign: Table>(foreign: Foreign.Type, as alias: String, kind: Join.Kind, _ build: (TableSource<Foreign>) -> Condition) -> TableSource<Foreign> {
        let source = TableSource(
            reference: .init(tableName: foreign.tableName, alias: alias),
            table: foreign
        )
        let condition = build(source)
        joins.append(Join(kind: kind, alias: alias, foreignName: foreign.tableName, condition: condition))
        
        return source
    }
}

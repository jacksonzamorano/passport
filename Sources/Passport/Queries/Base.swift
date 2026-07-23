import Foundation

public class BaseQueryProperties {
    public let identity: QueryIdentity
    public let arguments: [Argument]
    
    public let target: any Table.Type
    
    init<T>(query: Query<T>) {
        self.target = T.self
        self.identity = query.identity
        self.arguments = query.arguments
    }
}

public class Query<Base: Table> {
    var identity: QueryIdentity
    
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
}

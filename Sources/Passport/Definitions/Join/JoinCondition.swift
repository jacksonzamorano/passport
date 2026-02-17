fileprivate func resolveJoinField<T: Record>(_ path: KeyPath<T, Field>, defaultAlias: String) -> (String, String) {
    let field = T.field(forKeyPath: path)!
    switch field.field.descriptionLocation {
    case .stored(_):
        return (defaultAlias, field.name)
    case .remote(let remote):
        return (remote().base ?? defaultAlias, field.name)
    }
}

struct ResolvedJoinField {
    let alias: String
    let name: String
}

public struct JoinBase<T: Record> {
    var alias: String
    
    init(alias: String) {
        self.alias = alias
    }
    
    public func use(_ kp: KeyPath<T, Field>) -> JoinBaseFragment<T> {
        JoinBaseFragment {
            let field = resolveJoinField(kp, defaultAlias: alias)
            return ResolvedJoinField(alias: field.0, name: field.1)
        }
    }
}

public struct JoinThis<T: Record> {
    var alias: String
    
    init(alias: String) {
        self.alias = alias
    }
    
    public func use(_ kp: KeyPath<T, Field>) -> JoinThisFragment<T> {
        JoinThisFragment {
            let field = resolveJoinField(kp, defaultAlias: alias)
            return ResolvedJoinField(alias: field.0, name: field.1)
        }
    }
}

public struct JoinForeign<T: Record> {
    var alias: String
    
    init(alias: String) {
        self.alias = alias
    }
    
    public func use(_ kp: KeyPath<T, Field>) -> JoinForeignFragment<T> {
        JoinForeignFragment {
            let field = resolveJoinField(kp, defaultAlias: alias)
            return ResolvedJoinField(alias: field.0, name: field.1)
        }
    }
}
public struct JoinBaseFragment<T: Record> {
    private var resolver: () -> ResolvedJoinField
    
    init(_ resolver: @escaping () -> ResolvedJoinField) {
        self.resolver = resolver
    }
    
    fileprivate func resolve() -> ResolvedJoinField {
        resolver()
    }
}
public struct JoinThisFragment<T: Record> {
    private var resolver: () -> ResolvedJoinField
    
    init(_ resolver: @escaping () -> ResolvedJoinField) {
        self.resolver = resolver
    }
    
    fileprivate func resolve() -> ResolvedJoinField {
        resolver()
    }
}
public struct JoinForeignFragment<T: Record> {
    private var resolver: () -> ResolvedJoinField
    
    init(_ resolver: @escaping () -> ResolvedJoinField) {
        self.resolver = resolver
    }
    
    fileprivate func resolve() -> ResolvedJoinField {
        resolver()
    }
}

public struct JoinStringCondition<Base: Record, Local: Record, Foreign: Record>: ExpressibleByStringInterpolation, CustomStringConvertible {

    public var description: String { value }
    var value: String
    
    public typealias StringLiteralType = String
    public typealias StringInterpolation = StringBuilder
    
    public init(stringLiteral value: String) {
        self.value = value
    }
    
    public init(stringInterpolation: StringBuilder) {
        self.value = stringInterpolation.output
    }
    
    enum Component {
        case field(String, String), string(String), argument(String)
    }
    
    public struct StringBuilder: StringInterpolationProtocol {
        public typealias StringLiteralType = String
        
        private(set) var output = ""
        
        public init(literalCapacity: Int, interpolationCount: Int) {
            output.reserveCapacity(literalCapacity + interpolationCount * 4)
        }
        mutating public func appendLiteral(_ literal: StringLiteralType) {
            output += literal
        }
        mutating public func appendInterpolation(_ value: JoinBaseFragment<Base>) {
            let resolved = value.resolve()
            output += "\(resolved.alias).\(resolved.name)"
        }
        mutating public func appendInterpolation(_ value: JoinThisFragment<Local>) {
            let resolved = value.resolve()
            output += "\(resolved.alias).\(resolved.name)"
        }
        mutating public func appendInterpolation(_ value: JoinForeignFragment<Foreign>) {
            let resolved = value.resolve()
            output += "\(resolved.alias).\(resolved.name)"
        }
    }
}

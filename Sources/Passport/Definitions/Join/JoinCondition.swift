public struct JoinAlias<T: Record> {
    var alias: String
    
    init(alias: String) {
        self.alias = alias
    }
    
    public func use(_ kp: KeyPath<T, Field>) -> JoinFragment<T> {
        let field = T.field(forKeyPath: kp)!
        switch field.field.descriptionLocation {
        case .stored(_):
            return JoinFragment(alias: alias, name: field.name)
        case .remote(let r):
            return JoinFragment(alias: r().base ?? alias, name: field.name)
        }
    }
}
public struct JoinFragment<T: Record> {
    var alias: String
    var name: String
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
        mutating public func appendInterpolation(_ value: JoinFragment<Base>) {
            output += "\(value.alias).\(value.name)"
        }
        mutating public func appendInterpolation(_ value: JoinFragment<Local>) {
            output += "\(value.alias).\(value.name)"
        }
        mutating public func appendInterpolation(_ value: JoinFragment<Foreign>) {
            output += "\(value.alias).\(value.name)"
        }
    }
}

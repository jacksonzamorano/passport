import Foundation

public indirect enum QueryInterpolation: Sendable {
    case field(String, String), qualifiedField(String, String), literal(String), raw(String), argument(Int)
}

public struct QueryStringCondition<Principal: Record, Arguments: QueryArguments>: ExpressibleByStringInterpolation, CustomStringConvertible {

    public var description: String { components.description }
    var components: [QueryInterpolation] = []
    
    public typealias StringLiteralType = String
    public typealias StringInterpolation = StringBuilder
    
    public init(stringLiteral value: String) {
        self.components = [.raw(value)]
    }
    
    public init(stringInterpolation: StringBuilder) {
        self.components = stringInterpolation.output
    }

    
    public struct StringBuilder: StringInterpolationProtocol {
        public typealias StringLiteralType = String
        
        private(set) var output: [QueryInterpolation] = []
        
        public init(literalCapacity: Int, interpolationCount: Int) {
            output.reserveCapacity(literalCapacity + interpolationCount * 4)
        }
        mutating public func appendLiteral(_ literal: StringLiteralType) {
            output.append(.raw(literal))
        }
        mutating public func appendInterpolation(_ value: KeyPath<Principal, Field>) {
            let name = Principal.field(forKeyPath: value)!.name
            // Wrapping this in a string is required, as it makes a new string
            // Referencing the existing string results in a bad access
            output.append(.field("\(Principal.recordType.name)", name))
        }
        mutating public func appendInterpolation(_ value: KeyPath<Arguments, DataType>) {
            let index = Arguments._index(forKeyPath: value)!
            output.append(.argument(index))
        }
        mutating public func appendInterpolation<T: Record>(_ value: CTEAlias<T>) {
            output.append(.raw(value.name))
        }
        mutating public func appendInterpolation<T: Record>(_ value: CTEField<T>) {
            output.append(.qualifiedField(value.alias, value.fieldName))
        }
        mutating public func appendInterpolation(_ value: any RawRepresentable<String>) {
            output.append(.literal(value.rawValue))
        }
    }
}

public struct QueryStringSingleLocationCondition<Principal: Record>: ExpressibleByStringInterpolation, CustomStringConvertible {
    
    public var description: String { components.description }
    var components: [QueryInterpolation] = []
    
    public typealias StringLiteralType = String
    public typealias StringInterpolation = StringBuilder
    
    public init(stringLiteral value: String) {
        self.components = [.raw(value)]
    }
    
    public init(stringInterpolation: StringBuilder) {
        self.components = stringInterpolation.output
    }
    
    
    public struct StringBuilder: StringInterpolationProtocol {
        public typealias StringLiteralType = String
        
        private(set) var output: [QueryInterpolation] = []
        
        public init(literalCapacity: Int, interpolationCount: Int) {
            output.reserveCapacity(literalCapacity + interpolationCount * 4)
        }
        mutating public func appendLiteral(_ literal: StringLiteralType) {
            output.append(.raw(literal))
        }
        mutating public func appendInterpolation(_ value: KeyPath<Principal, Field>) {
            let name = Principal.field(forKeyPath: value)!.name
            // Wrapping this in a string is required, as it makes a new string
            // Referencing the existing string results in a bad access
            output.append(.field("\(Principal.recordType.name)", name))
        }
    }
}

import Foundation

public struct Argument: Sendable {
    public var name: String
    public var dataType: DeclaredType
}

public struct ArgumentReference: Sendable, IntoConditionValue {
    var name: String
    var index: Int
    var dataType: DataType
    var optional: Bool
 
    public func toConditionValue() -> QueryValue {
        return .argument(self)
    }
}

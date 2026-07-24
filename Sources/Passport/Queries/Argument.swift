import Foundation

public struct Argument: Sendable {
    var name: String
    var dataType: DataType
    var optional: Bool
}

public struct ArgumentReference: Sendable, IntoConditionValue {
    var name: String
    var index: Int
 
    public func toConditionValue() -> QueryValue {
        return .argument(self)
    }
}

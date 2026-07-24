import Foundation

public struct Join: Sendable {
    public enum Kind: Sendable {
        case inner, left, right
    }
    public let kind: Join.Kind
    public let alias: String
    public let relation: SourceOrigin
    public let condition: Condition
}

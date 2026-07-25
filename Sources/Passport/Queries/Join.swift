import Foundation

public struct Join: Sendable {
    public enum Kind: Sendable {
        case inner, left, right
        
        var joinGuaranteed: Bool {
            switch self {
            case .left: false
            default: true
            }
        }
        
        var fromGuaranteed: Bool {
            switch self {
            case .right: false
            default: true
            }
        }
    }
    public let kind: Join.Kind
    public let alias: String
    public let relation: Relation
    public let condition: Condition
}

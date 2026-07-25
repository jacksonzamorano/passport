import Foundation

public struct Relation: Sendable, Equatable {
    public let relationID: UUID = UUID()
    public let name: String
    public let source: SourceOrigin
    
    public static func ==(lhs: Relation, rhs: Relation) -> Bool {
        lhs.relationID == rhs.relationID
    }
}

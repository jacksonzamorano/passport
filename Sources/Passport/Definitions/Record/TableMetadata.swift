import Foundation

public struct TableMetadata: Sendable {
    public var tableName: String
    
    public init(tableName: String) {
        self.tableName = tableName
    }
}

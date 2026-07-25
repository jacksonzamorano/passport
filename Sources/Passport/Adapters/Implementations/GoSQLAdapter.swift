import Foundation

public final class GoSQLAdapter: Adapter {
    public enum FileStrategy {
        case unified, split
    }
    
    let fileStrategy: FileStrategy
    
    public init(fileStrategy: FileStrategy = .unified) {
        self.fileStrategy = fileStrategy
    }
    
    public func buildQuery(query: BuiltQuery, inContext context: AdapterContext) throws(AdapterError) {
        
    }
}

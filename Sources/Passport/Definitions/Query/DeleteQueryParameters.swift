import Foundation

public struct DeleteQueryParameters: Sendable {
    var wh: [QueryInterpolation]? = nil
    var cte: [String: Query] = [:]
    
    public init() { }
}

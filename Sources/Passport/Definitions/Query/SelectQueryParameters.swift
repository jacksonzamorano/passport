import Foundation

public struct SelectQueryParameters: Sendable {
    var wh: [QueryInterpolation]? = nil
    var skip: Int? = nil
    var sort: [(String, SortDirection)]? = nil
    var limit: Int? = nil
    var group: String? = nil
    var cte: [String: Query] = [:]
    var returnCount: ReturnCount = .many
    
    public init() { }
}

import Foundation

public struct SelectQueryParameters: Sendable {
    var wh: [QueryInterpolation]? = nil
    var skip: [QueryInterpolation]? = nil
    var sort: [(String, SortDirection)]? = nil
    var limit: Int? = nil
    var group: String? = nil
    var ctes: [QueryCTE] = []
    var returnCount: ReturnCount = .many
    
    public init() { }
}

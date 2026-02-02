import Foundation

public struct UpdateQueryParameters: Sendable {
    var set: [QueryInterpolation]? = nil
    var wh: [QueryInterpolation]? = nil
    var cte: [String: Query] = [:]
    var returnCount: ReturnCount = .many

    public init() { }
}

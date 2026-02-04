import Foundation

public struct UpdateQueryParameters: Sendable {
    var set: [QueryInterpolation]? = nil
    var wh: [QueryInterpolation]? = nil
    var ctes: [QueryCTE] = []
    var returnCount: ReturnCount = .many

    public init() { }
}

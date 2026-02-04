import Foundation

public struct DeleteQueryParameters: Sendable {
    var wh: [QueryInterpolation]? = nil
    var ctes: [QueryCTE] = []
    
    public init() { }
}

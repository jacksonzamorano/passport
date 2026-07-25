import Foundation

public protocol Adapter {
    func buildQuery(query: BuiltQuery, inContext context: AdapterContext) throws(AdapterError)
}

public enum AdapterErrorCode: Sendable {
    case typeNotSupported
}

public struct AdapterError: Error {
    public let code: AdapterErrorCode
    public let location: String
    
    public init(code: AdapterErrorCode, location: String) {
        self.code = code
        self.location = location
    }
}

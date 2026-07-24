import Foundation

public protocol Dialect: Sendable {
    func buildQuery(query: Query, context: RenderContext) throws(DialectError) -> String
//    func buildSelectQuery(query: SelectQuery) throws(DialectError) -> String
//    func buildInsertQuery(query: InsertQuery) throws(DialectError) -> String
//    func buildUpdateQuery(query: UpdateQuery) throws(DialectError) -> String
}

public class RenderContext {
    var arguments: [Argument] = []
    var argumentCount: Int { arguments.count }
    public init() {}
}

public enum DialectErrorCode: Int, Sendable {
    case conditionNotSupported,
         joinKindNotSupported
    
    var description: String {
        switch self {
        case .conditionNotSupported: "This dialect does not support this condition."
        case .joinKindNotSupported: "This dialect does not support this kind of join."
        }
    }
}

public struct DialectError: Error {
    let error: DialectErrorCode
    let entityName: String
    let context: String
    
    var string: String {
        "[D\(String(format: "%0", error.rawValue))] (\(entityName)): '\(context)' \(error.description)"
    }
}

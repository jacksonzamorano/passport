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

public enum DialectError: Error {
    case conditionNotSupported,
         joinKindNotSupported
}

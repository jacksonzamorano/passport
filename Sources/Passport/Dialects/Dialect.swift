import Foundation

public protocol Dialect: Sendable {
    func buildSelectQuery(query: SelectQuery) throws(DialectError) -> String
    func buildInsertQuery(query: InsertQuery) throws(DialectError) -> String
    func buildUpdateQuery(query: UpdateQuery) throws(DialectError) -> String
}

public enum DialectError: Error {
    case conditionNotSupported,
         joinKindNotSupported
}

import Foundation

public class InsertQueryBuilder<Into: Table, Return: ProjectionKey>: BaseQuery<Into, Return> {
    var insertFields: [InsertQuery.Field] = []
    
    public func insert(_ column: ColumnReference, value: IntoConditionValue) {
        self.insertFields.append(.init(column: column, value: value.toConditionValue()))
    }
    
    public func returning(_ value: IntoConditionValue, as alias: Return) {
        project(value, as: alias)
    }
}
extension InsertQueryBuilder where Into.Key == Return {
    public func returnAll() {
        for key in Into.Key.allCases {
            project(source[key], as: key)
        }
    }
}

public protocol Insert {
    static var name: String { get }
    
    associatedtype From: Table
    associatedtype ReturnType: ProjectionKey
    
    func insert(local: TableSource<From>, query: InsertQueryBuilder<From, ReturnType>)
}

public typealias InsertBuilder<Into: Table, Returning: ProjectionKey> = (TableSource<Into>, inout InsertQueryBuilder<Into, Returning>) -> Void

public final class InsertQuery: BaseQueryProperties, @unchecked Sendable {
    
    public struct Field: Sendable {
        let column: ColumnReference
        let value: QueryValue
    }

    public let insertFields: [Field]
    
    public init<Configuration: Insert>(configuration: Configuration) {
        let source = TableSource(reference: .init(tableName: Configuration.From.tableName, alias: Configuration.name), table: Configuration.From.self)
        let queryBuilder = InsertQueryBuilder<Configuration.From, Configuration.ReturnType>(name: Configuration.name, source: source)
        configuration.insert(local: source, query: queryBuilder)
        
        self.insertFields = queryBuilder.insertFields
        super.init(query: queryBuilder, target: source.reference)
    }
}

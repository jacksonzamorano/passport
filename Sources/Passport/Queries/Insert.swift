import Foundation

public class InsertQueryBuilder<Return: ProjectionKey>: BaseQuery<Return> {
    var insertFields: [InsertQuery.Field] = []
        
    public func into<T: Table>(_ table: T.Type, as alias: String) -> TableSource<T> {
        return bind(table, as: alias)
    }
    
    public func insert(_ column: ColumnReference, value: IntoConditionValue) {
        self.insertFields.append(.init(column: column, value: value.toConditionValue()))
    }
    
    public func returning(_ value: IntoConditionValue, as alias: Return) {
        project(value, as: alias)
    }
    
    public func returnAll<T: Table>(from tableSource: TableSource<T>) where T.Key == Return {
        for key in Return.allCases {
            returning(tableSource[key], as: key)
        }
    }
}

public protocol Insert {
    static var name: String { get }
    
    associatedtype ReturnType: ProjectionKey
    
    func insert(query: InsertQueryBuilder<ReturnType>)
}

public typealias InsertBuilder<Returning: ProjectionKey> = (inout InsertQueryBuilder<Returning>) -> Void

public final class InsertQuery: BaseQueryProperties, @unchecked Sendable {
    
    public struct Field: Sendable {
        let column: ColumnReference
        let value: QueryValue
    }

    public let insertFields: [Field]
    
    public init<Configuration: Insert>(configuration: Configuration) {
        let queryBuilder = InsertQueryBuilder<Configuration.ReturnType>(name: Configuration.name)
        configuration.insert(query: queryBuilder)
        
        self.insertFields = queryBuilder.insertFields
        super.init(query: queryBuilder)
    }
}

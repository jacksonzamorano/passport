import Foundation

public class InsertQueryBuilder<Return: ProjectionKey>: BaseQuery<Return> {
    var insertFields: [InsertQuery.Field] = []
        
    public func into<T: Table>(_ table: T.Type, as alias: String? = nil) -> LocalTableReference<T> {
        return bind(table, as: alias ?? T.tableName)
    }
    
    public func insert(_ column: LocalColumnReference, value: IntoConditionValue) {
        self.insertFields.append(.init(
            column: column.column,
            value: value.toConditionValue()
        ))
    }
    public func insertNull(_ column: LocalColumnReference) {
        self.insertFields.append(.init(
            column: column.column,
            value: nil,
        ))
    }
    
    public func returning(_ value: any IntoConditionValue, as alias: Return) {
        project(value, as: alias)
    }
    
    public func returnAll<T: Table>(_ tableSource: TableReference<T>) where T.Key == Return {
        for key in Return.allCases {
            let reference: ColumnReference = tableSource[key]
            returning(reference, as: key)
        }
    }
    
    public func returnAll<T: Table>(_ tableSource: LocalTableReference<T>) where T.Key == Return {
        for key in Return.allCases {
            let reference: ColumnReference = tableSource[key].column
            returning(reference, as: key)
        }
    }
}

public protocol Insert: IntoSchemaItem {
    associatedtype ReturnType: ProjectionKey
    
    func insert(query: InsertQueryBuilder<ReturnType>)
}

public extension Insert {
    func toSchemaItem() -> SchemaItem {
        .query(.insert(.init(configuration: self)))
    }
}

public typealias InsertBuilder<Returning: ProjectionKey> = (inout InsertQueryBuilder<Returning>) -> Void

public final class InsertQuery: BaseQueryProperties, @unchecked Sendable {
    
    public struct Field: Sendable {
        let column: ColumnReference
        let value: QueryValue?
    }

    public let insertFields: [Field]
    
    public init<Configuration: Insert>(configuration: Configuration) {
        let name = String(describing: type(of: configuration))
        
        let queryBuilder = InsertQueryBuilder<Configuration.ReturnType>(name: name)
        configuration.insert(query: queryBuilder)
        
        self.insertFields = queryBuilder.insertFields
        super.init(query: queryBuilder)
    }
    
    override func validate() throws(QueryValidationError) {
        try super.validate()
        if insertFields.isEmpty {
            throw .noOpInsert
        }
    }
}

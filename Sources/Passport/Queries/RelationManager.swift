//import Foundation
//
//public protocol RelationKeys: Hashable, Sendable, RawRepresentable where RawValue == String {}
//
//public class RelationBuilder<Source: Table, KeyedBy: RelationKeys> {
//    
//    var keyedColumns: [KeyedBy : RelationColumn] = [:]
//    
//    public func select(_ value: QueryValue, as alias: KeyedBy) {
//        let column = RelationColumn(columnName: alias.rawValue, value: value)
//        keyedColumns[alias] = column
//    }
//}
//
//public typealias RelationBuilderFunction<Source: Table, Keys: RelationKeys> = (TableSource<Source>, RelationBuilder<Source, Keys>) -> Void
//
//
//public class RelationManager<Source: Table, KeyedBy: RelationKeys> {
//    let relationName: String
//    let keyedColumns: [KeyedBy : RelationColumn]
//    let columns: [RelationColumn]
//    
//    let query: RelationQuery
//
//    fileprivate init(name: String, query: RelationQuery, _ builder: RelationBuilder<Source, KeyedBy>) {
//        self.relationName = name
//        self.query = query
//        self.keyedColumns = builder.keyedColumns
//        self.columns = Array(builder.keyedColumns.values)
//    }
//    
//    func relation() -> Relation {
//        Relation(relationName: relationName, sourceName: Source.tableName, columns: columns, query: query)
//    }
//    
//    func source() -> RelationSource<KeyedBy> {
//        RelationSource(self)
//    }
//
//    internal static func make(
//        name: String,
//        query: RelationQuery,
//        configuration: RelationBuilderFunction<Source, KeyedBy>
//    ) -> RelationManager<Source, KeyedBy> {
//        let source = TableSource(reference: .init(tableName: Source.tableName, alias: Source.tableName), table: Source.self)
//        let builder = RelationBuilder<Source, KeyedBy>.init()
//        configuration(source, builder)
//        return RelationManager(name: name, query: query, builder)
//    }
//}

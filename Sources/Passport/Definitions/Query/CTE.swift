import Foundation

@dynamicMemberLookup
public struct CTEAlias<T: Record>: Sendable {
    public let name: String

    init(name: String) {
        self.name = name
    }

    public subscript(dynamicMember keyPath: KeyPath<T, Field>) -> CTEField<T> {
        let namedField = T.field(forKeyPath: keyPath)!
        return CTEField(alias: name, fieldName: namedField.name)
    }
}

public struct CTEField<T: Record>: Sendable {
    let alias: String
    let fieldName: String

    init(alias: String, fieldName: String) {
        self.alias = alias
        self.fieldName = fieldName
    }
}

struct QueryCTE: Sendable {
    let name: String
    let record: any Record.Type
    let query: Query

    init(name: String, record: any Record.Type, query: Query) {
        self.name = name
        self.record = record
        self.query = query
    }
}

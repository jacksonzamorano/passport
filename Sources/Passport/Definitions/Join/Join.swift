import Foundation

public enum JoinType: Sendable {
    case inner
}

public typealias JoinConditionFn<BaseFields: Record, LocalFields: Record, ForeignFields: Record> = @Sendable (JoinAlias<BaseFields>, JoinAlias<LocalFields>, JoinAlias<ForeignFields>) -> JoinStringCondition<BaseFields, LocalFields, ForeignFields>

public struct Join<T: Record>: Sendable {
    public var joinName: String
    public var location: String
    public var joinType: JoinType
    public var condition: @Sendable () -> String
    
    public init<
        BaseFields: Record,
        LocalFields: Record,
        ForeignFields: Record
    >(
        _ baseName: String,
        _ baseFields: BaseFields.Type,
        _ localName: String,
        _ localFields: LocalFields.Type,
        _ foreignName: String,
        _ foreignFields: ForeignFields.Type,
        joinType: JoinType,
        condition: @escaping JoinConditionFn<BaseFields, LocalFields, ForeignFields>
    ) {
        let uuidTrim = UUID().uuidString.split(separator: "-")[1]
        let jn = "\(foreignName)_\(uuidTrim)"
        self.joinName = jn
        self.location = foreignName
        self.joinType = joinType
        self.condition = {
            return condition(JoinAlias(alias: baseName), JoinAlias(alias: localName), JoinAlias(alias: jn)).value
        }
    }
}

public struct AnyJoin: Sendable {
    public var joinName: String
    public var joinType: JoinType
    public var location: String
    public var condition: String
    
    public init<T: Record>(_ join: Join<T>) {
        self.joinName = join.joinName
        self.joinType = join.joinType
        self.location = join.location
        self.condition = join.condition()
    }
}

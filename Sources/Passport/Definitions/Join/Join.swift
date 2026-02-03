import Foundation
import CryptoKit

public enum JoinType: Sendable {
    case inner
}

public typealias JoinConditionFn<BaseFields: Record, LocalFields: Record, ForeignFields: Record> = @Sendable (JoinAlias<BaseFields>, JoinAlias<LocalFields>, JoinAlias<ForeignFields>) -> JoinStringCondition<BaseFields, LocalFields, ForeignFields>

public struct Join<T: Record>: Sendable {
    public var joinName: String
    public var location: String
    public var joinType: JoinType
    public var condition: @Sendable (String) -> String
    
    public init<
        BaseFields: Record,
        LocalFields: Record,
        ForeignFields: Record
    >(
        _ explicitAlias: String? = nil,
        _ baseName: String,
        _ baseFields: BaseFields.Type,
        _ localName: String,
        _ localFields: LocalFields.Type,
        _ foreignName: String,
        _ foreignFields: ForeignFields.Type,
        joinType: JoinType,
        condition: @escaping JoinConditionFn<BaseFields, LocalFields, ForeignFields>
    ) {
        let alias: String!
        if let explicitAlias {
            alias = "\(baseName)_\(explicitAlias)"
        } else {
            let hashInput = "\(baseName)-\(localName)-\(foreignName)-\(String(describing: condition))"
            let digest = SHA256.hash(data: Data(hashInput.utf8))
            let hex = digest.map { String(format: "%02x", $0) }.joined()
            alias = "\(foreignName)_\(hex.prefix(6))"
        }
        self.joinName = alias
        self.location = foreignName
        self.joinType = joinType
        self.condition = { base in
            return condition(JoinAlias(alias: base), JoinAlias(alias: localName), JoinAlias(alias: alias)).value
        }
    }
}

public struct AnyJoin: Sendable {
    public var joinName: String
    public var joinType: JoinType
    public var location: String
    public var condition: @Sendable (String) -> String
    
    public init<T: Record>(_ join: Join<T>) {
        self.joinName = join.joinName
        self.joinType = join.joinType
        self.location = join.location
        self.condition = join.condition
    }
}

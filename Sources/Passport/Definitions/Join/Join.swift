import Foundation

public func fnv1a64(_ string: String) -> String {
    let bytes = Array(string.utf8)
    
    var hash: UInt64 = 0xcbf29ce484222325  // FNV offset basis
    let prime: UInt64 = 0x100000001b3       // FNV prime
    
    for byte in bytes {
        hash ^= UInt64(byte)
        hash &*= prime
    }
    
    return String(format: "%016llx", hash)
}

public enum JoinType: Sendable {
    case inner, cross, left, right
}

public typealias JoinConditionFn<BaseFields: Record, LocalFields: Record, ForeignFields: Record> = @Sendable (JoinBase<BaseFields>, JoinThis<LocalFields>, JoinForeign<ForeignFields>) -> JoinStringCondition<BaseFields, LocalFields, ForeignFields>

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
            let digest = fnv1a64(hashInput)
            alias = "\(foreignName)_\(digest.prefix(6))"
        }
        self.joinName = alias
        self.location = foreignName
        self.joinType = joinType
        self.condition = { base in
            return condition(
                JoinBase(alias: base),
                JoinThis(alias: localName),
                JoinForeign(alias: alias)
            ).value
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

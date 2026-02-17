import Passport

@Record(type: .table("users"))
struct User {
    init() {}
    
    let id = DEFAULT_ID_FIELD
    let name = Field(.string)
    let archived = Field(.bool)
    let status = Field(.value(UserStatus.self))
    let parentId = Field(.int64, .foreignKey(\User.id))

    static let selectById = select(with: SelectByIdArgs.self) { query in
        query.filter("\(\User.id) = \(\.userId)")
        query.filter("\(\User.archived) = false")
        query.one()
    }
    
    static let selectAll = select(with: NoArguments.self) { query in
        query.filter("\(\User.status) = \(UserStatus.active)")
        query.many()
    }
    
    @Argument
    struct NoArguments { }
    @Argument
    struct SelectByIdArgs {
        let userId: DataType = .int64
    }
    
    @Argument
    struct IdList {
        let ids: DataType = .array(.int64)
    }
    static let getInIdList = select(with: IdList.self) { q in
        q.filter("\(\.id) IN (\(\.ids))")
    }
    
    static let insertUser = insert(\.name, \.archived)
    
    
    static let updateName = update(with: UpdateNameByIdArgs.self) { query in
        query.set("\(\User.name) = \(\UpdateNameByIdArgs.name)")
        query.filter("\(\User.id) = \(\.userId)")
    }
    
    @Argument
    struct UpdateNameByIdArgs {
        let userId: DataType = .int64
        let name: DataType = .string
    }
}

@Record(type: .query(User.self))
struct UserInfo {
    let id = fromBase(\.id)
    
    static let parent = join(User.self, type: .inner) { this, base, up in
        "\(this.use(\.id)) = \(up.use(\.id))"
    }
    
    let parentId = fromJoin(\.parent, \.id)
    
    @Argument
    struct Id {
        let _id: DataType = .int64
    }
    static let getUserInfoById = select(with: Id.self) { q in
        q.filter("\(\.id) = \(\._id) OR \(\.parentId) = \(\._id)")
    }
}

@Enum
enum UserStatus: String {
    case inactive, active, removedByAdmin
}

@Model
struct UserCreateDto {
    var name = Field(.string)
}

import Passport

@Record(type: .table("users"))
struct User {
    init() {}
    
    let id = DEFAULT_ID_FIELD
    let name = Field(.string)
    let archived = Field(.bool)
    let status = Field(.value(UserStatus.self))

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

@Enum
enum UserStatus: String {
    case inactive, active, removedByAdmin
}

@Model
struct UserCreateDto {
    var name = Field(.string)
}

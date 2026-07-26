import Passport

Schema(dialect: PostgreSQL()) {
    User()
    UserProfile()
    Post()
    Payment()
    
    SelectUserProfileQuery()
    SelectPostsQuery()
    InsertGetPostWithEmail()
    UpdateEmail()
    DeletePost()
    InsertPayment()
    UnverifyPayment()
    GetUnverifiedPayments()
    
    Migration {
        CreateTableMigrationStep(User.self)
        CreateTableMigrationStep(Post.self)
        CreateColumnMigrationStep(Post.self, column: .text)
    }
    
    Adapter(
        GoSQLAdapter(),
        generateInto: .gitRoot(appending: ["generated", "go"])
    )
}

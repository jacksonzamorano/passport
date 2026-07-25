import Passport

Schema(dialect: PostgreSQL()) {
    User()
    Post()
    
    SelectPostsQuery()
    InsertGetPostWithEmail()
    UpdateEmail()
    DeletePost()
    
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

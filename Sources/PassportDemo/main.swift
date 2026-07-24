import Passport

Schema(dialect: PostgreSQL()) {
    User()
    Post()
    
    SelectPostsQuery()
    InsertGetPostWithEmail()
    UpdateEmail()
    
    Migration {
        CreateTableMigrationStep(User.self)
        CreateTableMigrationStep(Post.self)
        CreateColumnMigrationStep(Post.self, column: .text)
    }
}

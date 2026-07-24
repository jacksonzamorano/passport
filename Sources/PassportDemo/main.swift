import Passport

Schema(dialect: PostgreSQL()) {
    User()
    Post()
    
    SelectPostsQuery()
    InsertGetPostWithEmail()
}

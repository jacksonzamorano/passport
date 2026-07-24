public struct User: Table {
    public enum Key: String, TableKey {
        case id, email, token, lastPostID
    }
    
    static public let tableName: String = "users"
    
    static public  func column(_ key: Key) -> Column {
        switch key {
        case .id: .uuid().required()
        case .email: .string().required()
        case .token: .string().nullable()
        case .lastPostID: .uuid().nullable()
        }
    }
}

public struct Post: Table {
    public enum Key: String, TableKey, ProjectionKey {
        case id, text, userID
    }
    
    static public let tableName: String = "posts"
    
    static public func column(_ key: Key) -> Column {
        switch key {
        case .id: .uuid().required()
        case .text: .string()
        case .userID: .uuid().required()
//        case .userID: .requiredReference(column: User.id)
        }
    }
}

public enum SelectPostsResult: String, ProjectionKey {
    case text, userEmail
}
public struct SelectPostsQuery: Select {
    public static let name: String = "selectPostsWithUserEmail"
    public typealias From = Post
    public enum ReturnType: String, ProjectionKey {
        case text, userEmail
    }
    
    public init() {}
    
    public func select(local: TableSource<Post>, query: SelectQueryBuilder<Post, ReturnType>) {
        let users = query.join(foreign: User.self, as: "user", kind: .inner) { user in
            user[.id] == local[.userID]
        }
        
        let emailFilter = query.argument("email", dataType: .string)
        query.filter {
            users[.email] == emailFilter
        }
        
        query.select(local[.text], as: .text)
        query.select(users[.email], as: .userEmail)
    }
}

public struct InsertPostQuery: Insert {
    public static let name: String = "insertPost"
    public typealias From = Post
    public typealias ReturnType = Post.Key
    
    public init() {}
    public func insert(local: TableSource<Post>, query: InsertQueryBuilder<Post, ReturnType>) {
        let textArgument = query.argument("text", dataType: .string)
        query.insert(local[.text], value: textArgument)
        query.returnAll()
    }
}

public struct InsertGetPostWithEmail: Select {
    public static let name: String = "insertAndGetPost"
    public typealias From = Post
    public enum ReturnType: String, ProjectionKey {
        case text, userEmail
    }
    
    public init() {}
    
    public func select(local: TableSource<Post>, query: SelectQueryBuilder<Post, ReturnType>) {
        let insertResultCTE = query.with(InsertPostQuery(), as: "inserted")
        let insertResult = query.join(cte: insertResultCTE, as: "insert", kind: .inner) { insert in
            insert[.id] == local[.id]
        }
        
        let users = query.join(foreign: User.self, as: "user", kind: .inner) { user in
            user[.id] == local[.userID]
        }
        query.select(users[.email], as: .userEmail)
        query.select(insertResult[.text], as: .text)
    }
}
//public let InsertUserQuery = Insert(into: User.self, as: "createUser") { users, query in
//    let email = query.argument("email", dataType: .string)
//    
//    query.insert(users[.email], value: email)
//}
//
//public let UpdateLastPostID = Update(User.self, as: "upateUserLastPostID") { users, query in
//    let userID = query.argument("userID", dataType: .uuid)
//    let posts = query.from(foreign: Post.self, as: "p", kind: .left)
//    
//    query.filter {
//        .all(users[.id] == userID, posts[.userID] == users[.id])
//    }
//    
//    query.set(users[.lastPostID], value: posts[.id])
//}

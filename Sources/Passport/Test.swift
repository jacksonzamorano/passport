public struct User: Table {
    public enum Key: String, TableKey {
        case id, email, token, lastPostID
    }
    
    static public let tableName: String = "users"
    
    public init() {}
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
    
    public init() {}
    static public func column(_ key: Key) -> Column {
        switch key {
        case .id: .uuid().required()
        case .text: .string()
        case .userID: .uuid().required().foreignKey(User.self, column: .id)
//        case .userID: .requiredReference(column: User.id)
        }
    }
}

public enum SelectPostsResult: String, ProjectionKey {
    case text, userEmail
}
public struct SelectPostsQuery: Select {
    public static let name: String = "selectPostsWithUserEmail"
    public enum ReturnType: String, ProjectionKey {
        case text, userEmail
    }
    
    public init() {}
    
    public func select(query: SelectQueryBuilder<ReturnType>) {
        let posts = query.from(Post.self, as: "posts")
        
        let users = query.join(foreign: User.self, as: "user", kind: .inner) { user in
            user[.id] == posts[.userID]
        }
        
        let emailFilter = query.argument("email", dataType: .string)
        query.filter {
            users[.email] == emailFilter
        }
        
        query.limit(10)
        
        query.select(posts[.text], as: .text)
        query.select(users[.email], as: .userEmail)
    }
}

public struct InsertPostQuery: Insert {
    public static let name: String = "insertPost"
    public typealias ReturnType = Post.Key
    
    public init() {}
    public func insert(query: InsertQueryBuilder<ReturnType>) {
        let posts = query.into(Post.self, as: "posts")
        
        let textArgument = query.argument("text", dataType: .string)
        query.insert(posts[.text], value: textArgument)
        
        query.returnAll(posts)
    }
}

public struct InsertGetPostWithEmail: Select {
    public static let name: String = "insertAndGetPost"
    public enum ReturnType: String, ProjectionKey {
        case text, userEmail
    }
    
    public init() {}
    
    public func select(query: SelectQueryBuilder<ReturnType>) {
        let result = query.from(InsertPostQuery(), as: "result")
        let users = query.join(foreign: User.self, as: "user", kind: .inner) { user in
            user[.id] == result[.userID]
        }
        query.select(users[.email], as: .userEmail)
        query.select(result[.text], as: .text)
    }
}

public struct UpdateEmail: Update {
    public static let name: String = "updateUserEmail"
    public typealias ReturnType = User.Key
    
    public init() {}
    
    public func update(query: UpdateQueryBuilder<User.Key>) {
        let users = query.update(User.self, as: "users")
        let updateEmail = query.argument("email", dataType: .string)
        
        query.set(users[.email], value: updateEmail)
        query.returnAll(from: users)
    }
}

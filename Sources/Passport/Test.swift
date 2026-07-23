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
    public enum Key: String, TableKey {
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

public let SelectPostsQuery = Select(from: Post.self, as: "selectPostsWithUserDetails") { posts, query in
    let users = query.join(foreign: User.self, as: "user", kind: .inner) { user in
        user[.id] == posts[.userID]
    }
    
    let emailFilter = query.argument("email", dataType: .string)
    query.filter {
        users[.email] == emailFilter
    }
    
    query.select(posts[.text])
    query.select(users[.email], as: "userEmail")
}

public let InsertUserQuery = Insert(into: User.self, as: "createUser") { users, query in
    let email = query.argument("email", dataType: .string)
    
    query.insert(users[.email], value: email)
}

public let UpdateLastPostID = Update(User.self, as: "upateUserLastPostID") { users, query in
    let userID = query.argument("userID", dataType: .uuid)
    let posts = query.from(foreign: Post.self, as: "p", kind: .left)
    
    query.filter {
        .all(users[.id] == userID, posts[.userID] == users[.id])
    }
    
    query.set(users[.lastPostID], value: posts[.id])
}

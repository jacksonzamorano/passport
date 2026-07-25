import Passport

struct User: Table {
    public enum Key: String, TableKey {
        case id, email, token, lastPostID
    }
    
    static public let tableName: String = "users"
    
    static func column(_ key: Key) -> Column {
        switch key {
        case .id: .uuid().required()
        case .email: .string().required()
        case .token: .string().nullable()
        case .lastPostID: .uuid().nullable()
        }
    }
}

struct Post: Table {
    enum Key: String, TableKey, ProjectionKey {
        case id, text, userID, createdDate
    }
    
    static public let tableName: String = "posts"
    
    static func column(_ key: Key) -> Column {
        switch key {
        case .id: .uuid().required()
        case .text: .string()
        case .userID: .uuid().required().foreignKey(User.self, column: .id)
        case .createdDate: .timezonedDate().required()
        }
    }
}

struct Payment: Table {
    
    enum Key: String, TableKey {
        case id, fromUserID, toUserID, amount
    }
    
    static let tableName: String = "payments"
    
    static func column(_ key: Key) -> Column {
        switch key {
        case .id: .uuid().required()
        case .fromUserID: .uuid().required().foreignKey(User.self, column: .id)
        case .toUserID: .uuid().required().foreignKey(User.self, column: .id)
        case .amount: .float64().required()
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
        query.sort(posts[.createdDate], direction: .descending)
        
        query.select(posts[.text], as: .text)
        query.select(users[.email], as: .userEmail)
    }
}

struct InsertPostQuery: Insert {
    static let name: String = "insertPost"
    typealias ReturnType = Post.Key
    
    func insert(query: InsertQueryBuilder<ReturnType>) {
        let posts = query.into(Post.self, as: "posts")
        
        let textArgument = query.argument("text", dataType: .string)
        query.insert(posts[.text], value: textArgument)
        
        query.returnAll(posts)
    }
}

struct InsertGetPostWithEmail: Select {
    static let name: String = "insertAndGetPost"
    enum ReturnType: String, ProjectionKey {
        case text, userEmail
    }
    
    
    func select(query: SelectQueryBuilder<ReturnType>) {
        let result = query.from(InsertPostQuery(), as: "result")
        let users = query.join(foreign: User.self, as: "user", kind: .inner) { user in
            user[.id] == result[.userID]
        }
        query.select(users[.email], as: .userEmail)
        query.select(result[.text], as: .text)
    }
}

struct UpdateEmail: Update {
    static let name: String = "updateUserEmail"
    typealias ReturnType = User.Key
    
    func update(query: UpdateQueryBuilder<User.Key>) {
        let users = query.update(User.self, as: "users")
        let updateEmail = query.argument("email", dataType: .string)
        
        query.set(users[.email], value: updateEmail)
        query.returnAll(from: users)
    }
}

struct DeletePost: Delete {
    static let name: String = "deletePost"
    typealias ReturnType = Post.Key
    
    func delete(query: DeleteQueryBuilder<Post.Key>) {
        let posts = query.from(Post.self)
        
        let postID = query.argument("postID", dataType: .uuid)
        query.filter {
            posts[.id] == postID
        }
        
        query.returnAll(from: posts)
    }
}

enum FullPayment: String, ProjectionKey {
    case id, fromUserEmail, toUserEmail, amount
}


struct InsertPayment: Select {
    struct InsertResult: Insert {
        static let name: String = "insertResult"
        typealias ReturnType = Payment.Key
        
        func insert(query: Passport.InsertQueryBuilder<Payment.Key>) {
            let into = query.into(Payment.self)
            
            let fromUserID = query.argument("fromUserID", dataType: .uuid)
            let toUserID = query.argument("toUserID", dataType: .uuid)
            let amount = query.argument("amount", dataType: .float64)
            
            query.insert(into[.fromUserID], value: fromUserID)
            query.insert(into[.toUserID], value: toUserID)
            query.insert(into[.amount], value: amount)
            query.returnAll(into)
        }
    }
    
    static let name: String = "insertResult"
    typealias ReturnType = FullPayment
    
    func select(query: SelectQueryBuilder<FullPayment>) {
        let insert = query.from(InsertResult(), as: "insert")
        
        let fromUser = query.join(foreign: User.self, as: "fromUser", kind: .inner) { fromUser in
            fromUser[.id] == insert[.fromUserID]
        }
        let toUser = query.join(foreign: User.self, as: "toUser", kind: .inner) { toUser in
            toUser[.id] == insert[.fromUserID]
        }
        
        query.resultTypeName("InsertedPayment")
        query.select(insert[.id], as: .id)
        query.select(insert[.amount], as: .amount)
        query.select(fromUser[.email], as: .fromUserEmail)
        query.select(toUser[.email], as: .toUserEmail)
    }
}

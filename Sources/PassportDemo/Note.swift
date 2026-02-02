import Passport

@Record(type: .table("notes"))
struct Note {
    let id = DEFAULT_ID_FIELD
    let title = Field(.string)
    let ownerId = Field(.int64, .foreignKey(\User.id))
    let content = Field(.string)
    let archiveTimestamp = Field(.optional(.datetime))

    
    static let deleteByOwner: Query = delete(
        with: DeleteByOwnerArguments.self
    ) { query in
        query.filter("\(\.ownerId) = \(\._ownerId)")
    }
    @Argument
    struct DeleteByOwnerArguments {
        var _ownerId: DataType = .int64
    }
}

@Record(type: .query(Note.self))
struct NoteCountQuery {
    let ownerId = fromBase(\.ownerId)
    let count = fromExpression(.int64) {
        return "COUNT(\(\.ownerId))"
    }

    static let noteCountByUser = select(with: UserIdArg.self) { query in
        query.filter("\(\.ownerId) = \(\._userId)")
        query.group(\.ownerId)
    }
    @Argument
    struct UserIdArg {
        var _userId: DataType = .int64
    }
    
    static let insertCount: Query = insert(\.ownerId, \.title, \.content)
}

@Record(type: .table("notes_allowed_users"))
struct NotesAllowedUsers {
    let id = DEFAULT_ID_FIELD
    let userId = Field(.int64)
    let noteId = Field(.int64)
    
}

@Record(type: .query(NotesAllowedUsers.self))
struct NotesWithUsers {
    let accessId = fromBase(\.id)
    static let note = join(Note.self, type: .inner) { notesAllowedUsers, _, note in
        return "\(notesAllowedUsers.use(\.noteId)) = \(note.use(\.id))"
    }
    static let user = join(User.self, type: .inner) { notesAllowedUsers, _, user in
        return "\(notesAllowedUsers.use(\.noteId)) = \(user.use(\.id))"
    }
    let ownerId = fromJoin(\.note, \.ownerId)
    static let owner = join(User.self, type: .inner) { _, this, user in
        return "\(this.use(\.ownerId)) = \(user.use(\.id))"
    }
    
    let userName = fromJoin(\.user, \.name)
    let noteTitle = fromJoin(\.note, \.title)
    let noteContent = fromJoin(\.note, \.content)
    let ownerName = fromJoin(\.owner, \.name)
    
    static let allNotes: Query = select(with: AllDataRequest.self) { query in
        query.many(20)
    }
}

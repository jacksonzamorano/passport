import Passport
import Foundation


@Model
struct GetNoteRequest {
    var userId: Field = .init(.int64)
}

@main
struct CrossKitDemo {
    static func main() {
        let postgres = SQLBuilder(Postgres())

        let go = GoConfiguration { cfg in
            cfg.packageName = "demo"
        }
        
        let root = packageRoot(#filePath)
        
        let schema = Schema("Demo") {
            
            User.self
            UserStatus.self
            UserCreateDto.self
            
            Note.self
            NoteCountQuery.self
            NotesAllowedUsers.self
            NotesWithUsers.self
            
            GetNoteRequest.self
            InviteUserRequest.self
            InviteUserRequestUser.self
            
        } routes: {
            userRoutes()
        }
        .output(Go(sqlBuilder: postgres, config: go)) {
            CodeBuilderConfiguration(
                root: root.appending(path: "demo/go"),
                generateRecords: .asRecords,
                generateRoutes: true
            )
        }
        .output(TypeScript(buildIndex: true)) {
            CodeBuilderConfiguration(
                root: root.appending(path: "demo/typescript"),
                generateRoutes: true
            )
        }
        .output(Swift(targetedPlatform: .bits64, standardizePropertyNames: true)) {
            CodeBuilderConfiguration(
                root: root.appending(path: "demo/swift"),
                generateRoutes: true
            )
        }
        
        
        try! schema.build()
    }
}

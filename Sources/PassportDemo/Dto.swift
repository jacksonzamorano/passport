import Passport

@Model
struct InviteUserRequest {
    var users = Field(.array(.model(InviteUserRequestUser.self)))
}

@Model
struct InviteUserRequestUser {
    var email = Field(.string)
    var name = Field(.string)
    var options = Field(.array(.string), Go.omitEmpty)
}

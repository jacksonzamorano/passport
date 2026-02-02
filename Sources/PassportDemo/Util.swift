import Passport

let DEFAULT_ID_FIELD = Field.init(.uuid, .primaryKey)

@Argument
struct AllDataRequest {}

@Argument
struct IdRequest {
    var id: DataType = .int64
}

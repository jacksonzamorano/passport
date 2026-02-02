import Testing
@testable import Passport

@Record(type: .table("users"))
struct TestUser {
    let id = Field(.int64, .primaryKey, .generatedAlways)
    let name = Field(.string)
    let nickname = Field(.optional(.string))
    let isActive = Field(.bool)
    let score = Field(.double)
    let uppercasedName = fromExpression(.string) { "UPPER(\(\.name))" }

    static let selectById = select(with: ByIdArgs.self) { query in
        query.filter("\(\TestUser.id) = \(\.userId)")
        query.one()
    }

    static let insertUser = insert(\.name, \.isActive)

    static let updateName = update(with: UpdateArgs.self) { query in
        query.set("\(\TestUser.name) = \(\UpdateArgs.newName)")
        query.filter("\(\TestUser.id) = \(\UpdateArgs.id)")
    }

    @Argument
    struct ByIdArgs {
        var userId: DataType = .int64
    }

    @Argument
    struct UpdateArgs {
        var id: DataType = .int64
        var newName: DataType = .string
    }
}

@Model
struct PetProfile {
    var petName = Field(.string)
    var ownerId = Field(.int64)
}

@Test func postgresCreateSkipsComputedFields() throws {
    let builder = SQLBuilder(Postgres())
    let createSQL = try builder.create(record: TestUser.self)

    #expect(createSQL != nil)
    #expect(createSQL?.contains("CREATE TABLE users") == true)
    #expect(createSQL?.contains("id INT8 NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY") == true)
    #expect(createSQL?.contains("name TEXT NOT NULL") == true)
    #expect(createSQL?.contains("nickname TEXT NOT NULL") == false)
    #expect(createSQL?.contains("nickname TEXT") == true)
    #expect(createSQL?.contains("uppercased_name") == false)
}

@Test func selectQueryRendersWhereAndLimit() {
    let sql = SQLBuilder(Postgres()).build(query: TestUser.selectById, forRecord: TestUser.self)

    #expect(sql.contains("SELECT users.id AS id"))
    #expect(sql.contains("FROM users"))
    #expect(sql.contains("WHERE users.id = $1"))
    #expect(sql.contains("LIMIT 1"))
}

@Test func insertQueryWrapsInsertWithReturningSelect() {
    let sql = SQLBuilder(Postgres()).build(query: TestUser.insertUser, forRecord: TestUser.self)

    #expect(sql.contains("WITH insert_result AS (INSERT INTO users (name, is_active) VALUES ($1, $2) RETURNING *)"))
    #expect(sql.contains("SELECT insert_result.id AS id"))
    #expect(sql.contains("insert_result.is_active AS is_active"))
}

@Test func updateQueryUsesCteAndArgumentOrder() {
    let sql = SQLBuilder(Postgres()).build(query: TestUser.updateName, forRecord: TestUser.self)

    #expect(sql.contains("WITH update_result AS (UPDATE users SET users.name = $2 WHERE users.id = $1)"))
    #expect(sql.contains("SELECT update_result.id AS id"))
    #expect(sql.contains("update_result.name AS name"))
}

@Test func swiftGeneratorStandardizesPropertyNames() throws {
    let lang = Swift(standardizePropertyNames: true)
    let session = CodeBuildSession()

    try lang.build(model: PetProfile.self, session: session)

    let contents = session.files.first(where: { $0.name == "\(PetProfile.name).swift" })?.contents ?? ""
    #expect(contents.contains("let petName: String"))
    #expect(contents.contains("let ownerId: Int64"))
    #expect(contents.contains("pet_name") == false)
}

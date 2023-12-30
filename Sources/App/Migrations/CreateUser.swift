import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("username", .string, .required)
            .field("password", .string, .required)
            .field("userType", .string, .required)
            .field("email", .string, .required)
            .field("name", .string)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}


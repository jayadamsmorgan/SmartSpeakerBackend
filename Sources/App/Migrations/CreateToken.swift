import Fluent

struct CreateToken: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("tokens")
            .id()
            .field("token", .string, .required)
            .field("userId", .uuid, .required)
            .field("issuedOn", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("tokens").delete()
    }
}


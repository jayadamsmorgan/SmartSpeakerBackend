import Fluent

struct CreateSpeaker: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("speakers")
            .id()
            .field("name", .string)
            .field("userId", .uuid, .required, .references("users", "id"))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("speakers").delete()
    }
}


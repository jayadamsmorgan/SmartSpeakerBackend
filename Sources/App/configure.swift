import NIOSSL
import Fluent
import FluentSQLiteDriver
import Vapor
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Use SQLite local database
    if app.environment == .testing {
        app.databases.use(DatabaseConfigurationFactory.sqlite(.memory), as: .sqlite)
    } else {
        app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)
    }

    // Use HS256 encryption for JWT signers
    app.jwt.signers.use(.hs256(key: "some-secret-key"))

    // Use BCrypt encryption for passwords
    if app.environment == .testing {
        app.passwords.use(.plaintext)
    } else {
        app.passwords.use(.bcrypt)
    }

    // Database migrations setup
    app.migrations.add(CreateToken())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateSpeaker())
    try await app.autoMigrate()

    // register routes
    try routes(app)
}


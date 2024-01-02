import NIOSSL
import Fluent
import FluentSQLiteDriver
import Vapor
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)
    app.jwt.signers.use(.hs256(key: "some-secret-key"))
    app.passwords.use(.bcrypt)
    app.migrations.add(CreateToken())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateSpeaker())

    try await app.autoMigrate()

    // register routes
    try routes(app)
}


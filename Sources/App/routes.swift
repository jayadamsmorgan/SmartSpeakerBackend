import Fluent
import Vapor

func routes(_ app: Application) throws {

    // Auth
    try app.register(collection: AuthController())

    // Users
    try app.grouped(UserAuthenticator()).register(collection: UserController())

    // Speakers
    try app.grouped(UserAuthenticator()).register(collection: SpeakerController())

}


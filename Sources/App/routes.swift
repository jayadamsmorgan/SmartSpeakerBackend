import Fluent
import Vapor

func routes(_ app: Application) throws {

    // Auth
    try app
        .register(collection:
        AuthController(authService: AuthService()))

    // Users
    try app
        .grouped(UserAuthenticator())
        .register(collection:
        UserController(userService: UserService()))

    // Speakers
    try app
        .grouped(UserAuthenticator())
        .register(collection: 
        SpeakerController(speakerService: SpeakerService()))

}


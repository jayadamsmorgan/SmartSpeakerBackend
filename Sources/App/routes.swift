import Fluent
import Vapor

func routes(_ app: Application) throws {
    // AUTH
    app.get { req async throws in
        "It works!"
    }

    try app.register(collection: AuthController())
    try app.register(collection: UserController())
}

import Fluent
import Vapor

func routes(_ app: Application) throws {
    // AUTH
    app.post("api", "v1", "auth", "login") { req async throws -> AuthResponse in
        let authDTO = try req.content.decode(AuthDTO.self)
        return await AuthService.authenticate(with: authDTO)
    }
    app.post("api", "v1", "auth", "register") { req async throws -> AuthResponse in
        let authDTO = try req.content.decode(AuthDTO.self)
        return await AuthService.register(with: authDTO)
    }

    //try app.register(collection: TodoController())
}

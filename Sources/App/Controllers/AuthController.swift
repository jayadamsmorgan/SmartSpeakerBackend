import Vapor

struct AuthController: RouteCollection {

    let authService: AuthService

    func boot(routes: RoutesBuilder) throws {
        let authRoutes = routes.grouped("auth")
        authRoutes.post("authenticate", use: authenticate)
        authRoutes.post("register", use: register)
    }

    func authenticate(req: Request) async throws -> ClientTokenReponse {
        req.logger.info("Authenticate: New authentication request: \(req.content).")
        let authDTO = try req.content.decode(AuthDTO.self)
        return try await authService.authenticate(req: req, authDTO: authDTO)
    }

    func register(req: Request) async throws -> ClientTokenReponse {
        req.logger.info("Register: New registration request: \(req.content).")
        let authDTO: AuthDTO
        authDTO = try req.content.decode(AuthDTO.self)
        return try await authService.register(req: req, authDTO: authDTO)
    }


}

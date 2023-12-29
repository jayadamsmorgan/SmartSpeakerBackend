import Vapor
import Fluent

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let authRoutes = routes.grouped("auth")
        authRoutes.post("authenticate", use: authenticate)
        authRoutes.post("register", use: register)
    }

    func authenticate(req: Request) async throws -> SessionToken {
        let logger = req.logger
        logger.info("Authenticate: New authentication request: \(req.content)")
        let authDTO = try req.content.decode(AuthDTO.self)
        var user: User?
        // Find user by either username, email or phoneNumber, whichever one is provided in AuthDTO request
        if let username = authDTO.username {
            user = try await req.db.query(User.self)
                .filter("username", .equal, username).first()
        } else if let email = authDTO.email {
            user = try await req.db.query(User.self)
                .filter("email", .equal, email).first()
        } else if let phoneNumber = authDTO.phoneNumber {
            user = try await req.db.query(User.self)
                .filter("phoneNumber", .equal, phoneNumber).first()
        }
        guard let user = user else {
            logger.info("Authenticate: Authenticating user not found.")
            throw Abort(.notFound)
        }
        logger.info("Authenticate: Authenticating user found: \(user)")
        guard let userpassword = authDTO.password else {
            logger.info("Authenticate: Password not provided.")
            throw Abort(.badRequest)
        }
        // TODO: Authenticate with authDTO password
        throw Abort(.notImplemented)
    }

    func register(req: Request) async throws -> SessionToken {
        let logger = req.logger
        logger.info("Register: New registration request: \(req.content)")
        let authDTO: AuthDTO
        do {
            authDTO = try req.content.decode(AuthDTO.self)
        } catch {
            logger.info("Register: Bad request: Content is not an AuthDTO instance.")
            throw Abort(.badRequest)
        }
        guard let username = authDTO.username else {
            logger.info("Register: Bad request: Content is misssing username.")
            throw Abort(.badRequest)
        }
        guard let email = authDTO.email else {
            logger.info("Register: Bad request: Content is missing email.")
            throw Abort(.badRequest)
        }
        guard let phoneNumber = authDTO.phoneNumber else {
            logger.info("Register: Bad request: Content is missing phoneNumber.")
            throw Abort(.badRequest)
        }
        guard let passwod = authDTO.password else {
            logger.info("Register: Bad request: Content is missing password.")
            throw Abort(.badRequest)
        }
        throw Abort(.notImplemented)
    }


}

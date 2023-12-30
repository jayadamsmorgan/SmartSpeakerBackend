import Vapor
import Fluent
import JWT

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
        let userQuery = User.query(on: req.db)
        if let username = authDTO.username {
            user = try await userQuery
                .filter("username", .equal, username)
                .first()
        } else if let email = authDTO.email {
            user = try await userQuery
                .filter("email", .equal, email)
                .first()
        } else if let phoneNumber = authDTO.phoneNumber {
            user = try await userQuery
                .filter("phoneNumber", .equal, phoneNumber)
                .first()
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
        guard let userId = user.id else {
            logger.info("Authenticate: Cannot get userId \(user).")
            throw Abort(.internalServerError)
        }
        let userTokens = try await Token.query(on: req.db)
            .filter("userId", .equal, userId)
            .limit(100)
            .all()
        let existingToken: Token?
        for token in userTokens {
            guard let issuedDate = Date.init(rfc1123: token.issuedOn) else {
                logger.info("Authenticate: Cannot get issued date of token \(token) for user with ID \(userId).")
                continue
            }
            guard let tokenId = token.id else {
                logger.info("Authenticate: Cannot get tokenId of token \(token).")
                continue
            }
            if issuedDate.addingTimeInterval(1000 * 60 * 60 * 24 * 30) >= Date.now {
                logger.info("Authenticate: Token with ID \(tokenId) is expired and being removed.")
                try await token.delete(on: req.db)
            }
            existingToken = token
        }
        if existingToken == nil {
            let jwtPayload: SessionToken = try req.jwt.verify()
            let newToken = Token()
            newToken.token = 
            newToken.issuedOn = Date.now.rfc1123
            try await newToken.save(on: req.db)
            return SessionToken()
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
        if try await User.query(on: req.db).filter("username", .equal, username).first() != nil {
            logger.info("Register: User with username \(username) already exists.")
            throw Abort(.notAcceptable)
        }
        guard let email = authDTO.email else {
            logger.info("Register: Bad request: Content is missing email.")
            throw Abort(.badRequest)
        }
        if try await User.query(on: req.db).filter("email", .equal, email).first() != nil {
            logger.info("Register: User with email \(email) already exists.")
            throw Abort(.notAcceptable)
        }
        guard let phoneNumber = authDTO.phoneNumber else {
            logger.info("Register: Bad request: Content is missing phoneNumber.")
            throw Abort(.badRequest)
        }
        if try await User.query(on: req.db).filter("phoneNumber", .equal, phoneNumber).first() != nil {
            logger.info("Register: User with phone number \(phoneNumber) already exists.")
            throw Abort(.notAcceptable)
        }
        guard let password = authDTO.password else {
            logger.info("Register: Bad request: Content is missing password.")
            throw Abort(.badRequest)
        }
        let passwordHash = try req.password.hash(password)
        let user = User(id: UUID.generateRandom(), username: username, email: email, phoneNumber: phoneNumber, name: nil, passwordHash: passwordHash)
        try await user.create(on: req.db)
        logger.info("Register: User \(user) created successfully.")
        let token = Token(id: UUID.generateRandom())
    }


}

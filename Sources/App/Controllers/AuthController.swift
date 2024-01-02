import Vapor
import Fluent
import JWT

struct AuthController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let authRoutes = routes.grouped("auth")
        authRoutes.post("authenticate", use: authenticate)
        authRoutes.post("register", use: register)
    }

    func createNewToken(userId: UUID, req: Request) async throws -> Token {
        let jwtPayload = SessionToken(userId: userId)
        let tokenStr = try req.jwt.sign(jwtPayload)
        let newToken = Token(token: tokenStr, userId: userId)
        do {
            try await newToken.save(on: req.db)
        } catch {
            req.logger.info("createNewToken: Cannot save token for user with ID \(userId.uuidString).")
            throw Abort(.internalServerError)
        }
        req.logger.info("New token for user with ID \(userId) saved successfully.")
        return newToken
    }

    func authenticate(req: Request) async throws -> ClientTokenReponse {
        let logger = req.logger
        logger.info("Authenticate: New authentication request: \(req.content).")
        let authDTO = try req.content.decode(AuthDTO.self)
        var user: User?
        // Find user by either username, or email, whichever one is provided in AuthDTO request
        let userQuery = User.query(on: req.db)
        if let username = authDTO.username {
            user = try await userQuery
                .filter("username", .equal, username)
                .first()
        } else if let email = authDTO.email {
            user = try await userQuery
                .filter("email", .equal, email)
                .first()
        }
        guard let user = user else {
            logger.info("Authenticate: Authenticating user not found.")
            throw Abort(.notFound)
        }
        logger.info("Authenticate: Authenticating user found: \(user).")
        guard let userpassword = authDTO.password else {
            logger.info("Authenticate: Password not provided.")
            throw Abort(.badRequest)
        }
        guard let userId = user.id else {
            logger.info("Authenticate: Cannot get userId \(user).")
            throw Abort(.internalServerError)
        }
        if try !req.password.verify(userpassword, created: user.passwordHash){
            logger.info("Authenticate: Wrong password provided for authentication request \(authDTO).")
            throw Abort(.badRequest)
        }
        let userTokens = try await Token.query(on: req.db)
            .filter("userId", .equal, userId)
            .limit(100)
            .all()
        var existingToken: Token?
        for token in userTokens {
            guard let issuedDate = Date.init(rfc1123: token.issuedOn) else {
                logger.info("Authenticate: Cannot get issued date of token \(token) for user with ID \(userId).")
                continue
            }
            guard let tokenId = token.id else {
                logger.info("Authenticate: Cannot get tokenId of token \(token).")
                continue
            }
            if issuedDate.addingTimeInterval(1000 * 60 * 60 * 24 * 30) <= Date.now {
                logger.info("Authenticate: Token with ID \(tokenId) is expired and being removed.")
                try await token.delete(on: req.db)
                continue
            }
            existingToken = token
        }
        guard let existingToken = existingToken else {
            let token = try await createNewToken(userId: userId, req: req)
            return ClientTokenReponse(token: token.token)
        }
        return ClientTokenReponse(token: existingToken.token)
    }

    func register(req: Request) async throws -> ClientTokenReponse {
        let logger = req.logger
        logger.info("Register: New registration request: \(req.content).")
        let authDTO: AuthDTO
        authDTO = try req.content.decode(AuthDTO.self)
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
        guard let password = authDTO.password else {
            logger.info("Register: Bad request: Content is missing password.")
            throw Abort(.badRequest)
        }
        let passwordHash = try req.password.hash(password)
        let user = User(userType: .user, username: username, email: email, passwordHash: passwordHash)
        try await user.create(on: req.db)
        logger.info("Register: User \(user) created successfully.")
        guard let userId = user.id else {
            logger.info("Register: Cannot get userId of new user \(user).")
            throw Abort(.internalServerError)
        }
        let token = try await createNewToken(userId: userId, req: req)
        return ClientTokenReponse(token: token.token)
    }


}

import Vapor

struct UserAuthenticator: AsyncBearerAuthenticator {

    func authenticate(
        bearer: BearerAuthorization,
        for request: Request
    ) async throws {
        // Get the token from database
        guard let token = try await Token.query(on: request.db).filter("token", .equal, bearer.token).first() else {
            request.logger.info("UserAuthenticator: No token found: \(bearer.token)")
            throw Abort(.unauthorized)
        }
        request.logger.info("UserAuthenticator: Token found in database: \(token)")
        guard let user = try await User.query(on: request.db).filter("userId", .equal, token.userId).first() else {
            request.logger.info("UserAuthenticator: Could not locate user with userId \(token.userId)")
            throw Abort(.unauthorized)
        }
        request.logger.info("UserAuthenticator: User found in database: \(user)")
        request.auth.login(user)
    }

}


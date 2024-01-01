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
        if Date.now >= Date(rfc1123: token.issuedOn)!.addingTimeInterval(1000 * 60 * 60 * 24 * 30) {
            request.logger.info("UserAuthenticator: Token \(token) is expired.")
            throw Abort(.unauthorized)
        }
        guard let user = try await User.find(token.userId, on: request.db) else {
            request.logger.info("UserAuthenticator: Could not locate user with userId \(token.userId)")
            throw Abort(.unauthorized)
        }
        request.logger.info("UserAuthenticator: User found in database: \(user)")
        request.auth.login(user)
    }

}


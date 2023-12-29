import Vapor
import Fluent
import JWT

// Example JWT payload.
struct SessionToken: Content, Authenticatable, JWTPayload {

    // Constants
    let expirationTime: TimeInterval = 60 * 60 * 24 * 30 // 30 days

    // Token Data
    var expiration: ExpirationClaim
    var userId: UUID

    init(userId: UUID) {
        self.userId = userId
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }

    init(user: User) throws {
        self.userId = try user.requireID()
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }

    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}

final class Token: Content, Model {

    static let schema = "tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "token")
    var token: String

    @Field(key: "userId")
    var userId: UUID

    @Field(key: "isExpired")
    var isExpired: Bool

}

struct ClientTokenReponse: Content {
    var token: String
}


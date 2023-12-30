import Vapor
import Fluent
import JWT


struct SessionToken: Content, Authenticatable, JWTPayload {

    var expiration: ExpirationClaim
    var userId: UUID

    init(userId: UUID) {
        let expirationTime: TimeInterval = 60 * 60 * 24 * 30 // 30 days
        self.userId = userId
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(expirationTime))
    }

    init(user: User) throws {
        let expirationTime: TimeInterval = 60 * 60 * 24 * 30 // 30 days
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

    @Field(key: "issuedOn")
    var issuedOn: String

    init() { }
    
    init(id: UUID? = nil, token: String, userId: UUID, issuedOn: String) {
        self.id = id
        self.token = token
        self.userId = userId
        self.issuedOn = issuedOn
    }

    init(token: String, userId: UUID, issuedOn: String) {
        self.token = token
        self.userId = userId
        self.issuedOn = issuedOn
    }

    init(token: String, userId: UUID) {
        self.token = token
        self.userId = userId
        self.issuedOn = Date.now.rfc1123
    }

    init(id: UUID? = nil, token: String, userId: UUID) {
        self.id = id
        self.token = token
        self.userId = userId
        self.issuedOn = Date.now.rfc1123
    }
}

struct ClientTokenReponse: Content {
    var token: String
}


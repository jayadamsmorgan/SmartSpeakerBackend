import Vapor
import Fluent

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "userType")
    var userType: UserType
    
    @Field(key: "username")
    var username: String

    @Field(key: "email")
    var email: String?

    @Field(key: "name")
    var name: String?

    @Field(key: "password")
    var passwordHash: String

    init() { }

    init(id: UUID? = nil,
        userType: UserType = .user,
        username: String,
        email: String?,
        name: String? = nil,
        passwordHash: String) {
        self.id = id
        self.username = username
        self.email = email
        self.name = name
        self.passwordHash = passwordHash
    }

}

enum UserType: String, Codable {
    case admin = "ADMIN"
    case user = "USER"
}

struct UserInfoDTO: Content {
    var id: String
    var userType: UserType
    var name: String?
    var username: String
    var email: String?
}



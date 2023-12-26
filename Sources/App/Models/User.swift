import Vapor
import Fluent

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "username")
    var username: String

    @Field(key: "email")
    var email: String?

    @Field(key: "phoneNumber")
    var phoneNumber: String?

    @Field(key: "name")
    var name: String?

    @Field(key: "password")
    var password: String

    init() { }

    init(id: UUID? = nil, username: String, password: String) {
        self.id = id
        self.username = username
        self.password = password
    }

}

struct UserInfoDTO: Content {
    var id: String
    var name: String?
    var username: String?
    var email: String?
    var phoneNumber: String?
}



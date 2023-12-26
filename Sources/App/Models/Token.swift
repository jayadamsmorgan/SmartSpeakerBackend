import Vapor
import Fluent

final class Token: Model, Content {

    static let schema = "tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "token")
    var token: String

    @Field(key: "userID")
    var userID: UUID

    @Field(key: "dateOfCreation")
    var dateOfCreation: String // ?

    init() { }

    init(id: UUID? = nil, token: String, userID: UUID) {
        self.id = id
        self.token = token
        self.userID = userID
    }
    
}

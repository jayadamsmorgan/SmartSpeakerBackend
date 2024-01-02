import Fluent
import Vapor

final class Speaker: Model, Content {

    static let schema = "speakers"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "userId")
    var user: User

    @Field(key: "name")
    var name: String

    init() { }

    init(id: UUID? = nil, userId: User.IDValue, name: String) {
        self.id = id
        self.$user.id = userId
        self.name = name
    }

}

struct SpeakerUpdateDTO: Content {
    let name: String
}


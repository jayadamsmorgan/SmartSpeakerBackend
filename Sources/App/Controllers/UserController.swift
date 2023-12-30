import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: index)
        users.group(":userID") { user in
            user.get(use: get)
        }
    }

    func index(req: Request) async throws -> [UserInfoDTO] {
        let users = try await User.query(on: req.db).limit(100).all()
        var userDTOs: [UserInfoDTO] = []
        for user in users {
            if let userIdStr = user.id?.uuidString {
                let userDTO = UserInfoDTO(id: userIdStr, name: user.name, username: user.username)
                userDTOs.append(userDTO)
            }
        }
        return userDTOs
    }

    func get(req: Request) async throws -> User {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return user
    }

}


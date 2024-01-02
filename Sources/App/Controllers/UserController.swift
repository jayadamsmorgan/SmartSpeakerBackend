import Vapor

struct UserController: RouteCollection {

    let userService: UserService

    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: userService.getUserMakingRequest)
        users.group(":userId") { user in
            user.get(use: get)
        }
    }

    func get(req: Request) async throws -> UserInfoDTO {
        guard let userId = req.parameters.get("userId") else {
            throw Abort(.badRequest)
        }
        return try await userService.getUserById(req: req, userId: userId)
    }

}


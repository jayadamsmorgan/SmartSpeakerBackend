import Vapor

struct UserController: RouteCollection {

    let userService: UserService

    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: userService.getUserMakingRequest)
        users.put(use: updateUser)
        users.group(":userId") { user in
            user.get(use: getUserById)
            user.put(use: updateUser)
        }
    }

    func getUserById(req: Request) async throws -> UserInfoDTO {
        guard let userId = req.parameters.get("userId") else {
            req.logger.info("getUserById: Cannot get userId from request.")
            throw Abort(.badRequest)
        }
        return try await userService.getUserById(req: req, userId: userId)
    }

    func updateUser(req: Request) async throws -> UserInfoDTO {
        guard let userId = req.parameters.get("userId") else {
            return try await userService.updateUser(req: req)
        }
        return try await userService.updateUser(req: req, forId: userId)
    }

}


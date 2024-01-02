import Vapor
import Fluent

struct UserService {

    func getUserMakingRequest(req: Request) async throws -> UserInfoDTO {
        guard let user = req.auth.get(User.self) else {
            req.logger.info("GET /users: Cannot get User from request.")
            throw Abort(.internalServerError)
        }
        return try UserInfoDTO(id: user.requireID().uuidString, userType: user.userType, name: user.name, username: user.username)
    }

    func getUserById(req: Request, userId: String) async throws -> UserInfoDTO {
        guard let user = try await User.find(UUID(userId), on: req.db) else {
            throw Abort(.notFound)
        }
        guard let userMakingRequest = req.auth.get(User.self) else {
            req.logger.info("GET /users/:userId: Cannot get User from request.")
            throw Abort(.internalServerError)
        }
        let userIdStr = try user.requireID().uuidString
        if try userMakingRequest.requireID().uuidString == userIdStr || userMakingRequest.userType == .admin {
            // If a user is getting info about himself or it's admin who is making request give full info
            return UserInfoDTO(
                        id: userIdStr,
                        userType: user.userType,
                        name: user.name,
                        username: user.username,
                        email: user.email)
        }
        return UserInfoDTO(id: userIdStr, userType: user.userType, name: user.name, username: user.username)

    }

}


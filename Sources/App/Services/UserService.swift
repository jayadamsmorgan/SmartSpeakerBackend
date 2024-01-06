import Vapor
import Fluent

struct UserService {

    func getUserMakingRequest(req: Request) async throws -> UserInfoDTO {
        guard let user = req.auth.get(User.self) else {
            req.logger.info("getUserMakingRequest: Cannot get User from request.")
            throw Abort(.unauthorized)
        }
        return try UserInfoDTO(
            id: user.requireID().uuidString,
            userType: user.userType,
            name: user.name,
            username: user.username,
            email: user.email)
    }

    func getUserById(req: Request, userId: String) async throws -> UserInfoDTO {
        guard let user = try await User.find(UUID(userId), on: req.db) else {
            req.logger.info("getUserById: Cannot find user with id \(userId).")
            throw Abort(.notFound)
        }
        guard let userMakingRequest = req.auth.get(User.self) else {
            req.logger.info("getUserById: Cannot get User from request.")
            throw Abort(.unauthorized)
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

    func updateUser(req: Request, forId userId: String? = nil) async throws -> UserInfoDTO {
        guard let userMakingRequest = req.auth.get(User.self) else {
            req.logger.info("updateUser: Cannot get User from request.")
            throw Abort(.unauthorized)
        }
        let userId = try userId ?? userMakingRequest.requireID().uuidString
        guard let user = try await User.find(UUID(userId), on: req.db) else {
            req.logger.info("updateUser: Cannot find user with id \(userId).")
            throw Abort(.notFound)
        }
        let userIdStr = try user.requireID().uuidString
        // If a user is updating his info or it's admin who is making request update user and return full info
        if try userMakingRequest.requireID().uuidString != userIdStr && userMakingRequest.userType != .admin {
            throw Abort(.unauthorized)
        }

        let updateRequest = try req.content.get(UserUpdateDTO.self)
        if let userEmailCheck = try await User.query(on: req.db).filter("email", .equal, updateRequest.email).first() {
            if try userEmailCheck.requireID().uuidString != user.requireID().uuidString {
                req.logger.info("updateUser: Found user with email \(updateRequest.email)")
                throw Abort(.notAcceptable)
            }
        }
        if let userUsernameCheck = try await User.query(on: req.db).filter("username", .equal, updateRequest.username).first() {
            if try userUsernameCheck.requireID().uuidString != user.requireID().uuidString {
                req.logger.info("updateUser: Found user with username \(updateRequest.username)")
                throw Abort(.notAcceptable)
            }
        }
        user.name = updateRequest.name
        user.email = updateRequest.email
        user.username = updateRequest.username
        return try UserInfoDTO(
            id: user.requireID().uuidString,
            userType: user.userType,
            name: user.name,
            username: user.username,
            email: user.email)
    }

}


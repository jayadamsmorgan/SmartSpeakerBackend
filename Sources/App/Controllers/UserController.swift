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
        guard let userMakingRequest = req.auth.get(User.self) else {
            req.logger.info("GET /users: Cannot get User from request.")
            throw Abort(.internalServerError)
        }
        var userDTOs: [UserInfoDTO] = []
        _ = try await User.query(on: req.db).limit(100).all().map { user in
            let userIdStr = try user.requireID().uuidString
            if try userMakingRequest.requireID().uuidString == userIdStr
                || userMakingRequest.userType == .admin {
                // If a user is getting info about himself or it's admin who is making request give full info
                userDTOs.append(UserInfoDTO(
                                    id: userIdStr,
                                    userType: user.userType,
                                    name: user.name,
                                    username: user.username,
                                    email: user.email))
            } else {
                userDTOs.append(UserInfoDTO(
                                    id: userIdStr,
                                    userType: user.userType,
                                    name: user.name,
                                    username: user.username))
            }
        }
        return userDTOs
    }

    func get(req: Request) async throws -> UserInfoDTO {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
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


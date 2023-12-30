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

    func getUserFromRequest(req: Request) async -> User? {
        do {
            guard let tokenStr = req.headers.bearerAuthorization?.token else {
                req.logger.error("isRequestAuthorized: Cannot find token in request.")
                return nil
            }
            guard let token = try await Token.query(on: req.db).filter("token", .equal, tokenStr).first() else {
                req.logger.error("isRequestAuthorized: Cannot find token \(tokenStr) in database.")
                return nil
            }
            guard let user = try await User.query(on: req.db).filter("id", .equal, token.userId).first() else {
                req.logger.error("isRequestAuthorized: Cannot find user for token \(token).")
                return nil
            }
            return user
        } catch {
            return nil
        }
    }

    func index(req: Request) async throws -> [UserInfoDTO] {
        guard let userMakingRequest = await getUserFromRequest(req: req) else {
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
            }
            userDTOs.append(UserInfoDTO(
                                id: userIdStr,
                                userType: user.userType,
                                name: user.name,
                                username: user.username))
        }
        return userDTOs
    }

    func get(req: Request) async throws -> UserInfoDTO {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        guard let userMakingRequest = await getUserFromRequest(req: req) else {
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


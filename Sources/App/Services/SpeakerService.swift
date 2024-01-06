import Vapor
import Fluent

struct SpeakerService {

    fileprivate func findSpeakerById(req: Request, speakerId: String) async throws -> Speaker {
        guard let speaker = try await Speaker.find(UUID(speakerId), on: req.db) else {
            req.logger.info("PUT /speakers/:id: Cannot find speaker with ID \(speakerId).")
            throw Abort(.notFound)
        }
        return speaker
    }

    func getSpecificUserSpeakers(req: Request, forId userId: String) async throws -> [Speaker] {
        guard let user = try await User.find(UUID(userId), on: req.db) else {
            req.logger.info("getSpecificUserSpeakers: Cannot find user with ID \(userId).")
            throw Abort(.notFound)
        }
        guard let userMakingRequest = req.auth.get(User.self) else {
            req.logger.info("getSpecificUserSpeakers: Cannot get user making request.")
            throw Abort(.unauthorized)
        }
        if try userMakingRequest.requireID().uuidString != user.requireID().uuidString && userMakingRequest.userType != .admin {
            throw Abort(.unauthorized)
        }
        return try await getUserSpeakers(req: req, userMakingRequest: user)
    }

    func getUserSpeakers(req: Request, userMakingRequest: User) async throws -> [Speaker] {
        try await Speaker.query(on: req.db).filter("userId", .equal, userMakingRequest.requireID()).all()
    }

    func getSpeakerById(req: Request, userMakingRequest user: User, speakerId: String) async throws -> Speaker {
        let speaker = try await findSpeakerById(req: req, speakerId: speakerId)
        if try user.requireID().uuidString != speaker.user.requireID().uuidString && user.userType != .admin {
            throw Abort(.unauthorized)
        }
        return speaker
    }

    func createNewSpeakerForUser(req: Request, forId userId: String) async throws -> Speaker {
        guard let user = try await User.find(UUID(userId), on: req.db) else {
            req.logger.info("createNewSpeakerForUser: Cannot find user with ID \(userId).")
            throw Abort(.notFound)
        }
        guard let userMakingRequest = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        if try userMakingRequest.requireID().uuidString != user.requireID().uuidString && userMakingRequest.userType != .admin {
            throw Abort(.unauthorized)
        }
        return try await createNewSpeaker(req: req, user: user)
    }

    func createNewSpeaker(req: Request, user: User) async throws -> Speaker {
        let speakerUpdateDTO = try req.content.get(SpeakerUpdateDTO.self)
        let speakers = try await Speaker.query(on: req.db).filter("userId", .equal, user.requireID()).all()
        if speakers.contains(where: { $0.name == speakerUpdateDTO.name }) {
            req.logger.info("POST /speakers: User already has speaker with name \(speakerUpdateDTO.name)")
            throw Abort(.notAcceptable)
        }
        let speaker = try Speaker(userId: user.requireID(), name: speakerUpdateDTO.name)
        do {
            try await speaker.create(on: req.db)
        } catch {
            req.logger.info("POST /speakers: Cannot create Speaker.")
            throw Abort(.internalServerError)
        }
        return speaker
    }

    func updateUserSpeaker(req: Request, user: User, speakerId: String) async throws -> Speaker {
        let speaker = try await findSpeakerById(req: req, speakerId: speakerId)

        if try speaker.$user.$id.wrappedValue.uuidString != user.requireID().uuidString && user.userType != .admin {
            req.logger.info("PUT /speakers/:id: User \(user) is not able to update Speaker with ID \(speakerId).")
            throw Abort(.unauthorized)
        }
        let speakerUpdateDTO: SpeakerUpdateDTO
        do {
            speakerUpdateDTO = try req.content.get(SpeakerUpdateDTO.self)
        } catch {
            req.logger.info("PUT /speakers/:id: Cannot get SpeakerUpdateDTO from request.")
            throw Abort(.badRequest)
        }
        speaker.name = speakerUpdateDTO.name
        do {
            try await speaker.update(on: req.db)
        } catch {
            req.logger.info("PUT /speakers/:id: Cannot update Speaker with ID \(speakerId).")
            throw Abort(.internalServerError)
        }
        return speaker
    }

    func deleteUserSpeaker(req: Request, userMakingRequest user: User, speakerId: String) async throws -> HTTPStatus {
        let speaker = try await findSpeakerById(req: req, speakerId: speakerId)

        if try speaker.$user.$id.wrappedValue.uuidString != user.requireID().uuidString && user.userType != .admin {
            req.logger.info("DELETE /speakers/:id: User \(user) is not able to update Speaker with ID \(speakerId).")
            throw Abort(.unauthorized)
        }
        do {
            try await speaker.delete(on: req.db)
        } catch {
            req.logger.info("DELETE /speakers/:id: Cannot delete Spaeker with ID \(speakerId).")
            throw Abort(.internalServerError)
        }
        return .ok
    }

}


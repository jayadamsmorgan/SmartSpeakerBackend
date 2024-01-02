import Fluent
import Vapor

struct SpeakerController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let speakers = routes.grouped("speakers")
        speakers.get(use: get)
        speakers.group(":speakerId") { speaker in
            speaker.get(use: getById)
            speaker.put(use: updateSpeaker)
        }
        speakers.post(use: createNewSpeaker)
    }

    func get(req: Request) async throws -> [Speaker] {
        guard let user = req.auth.get(User.self) else {
            req.logger.info("GET /speakers: Cannot get user from request.")
            throw Abort(.internalServerError)
        }
        let speakers = try await Speaker.query(on: req.db).filter("userId", .equal, user.requireID()).all()
        return speakers
    }

    func getById(req: Request) async throws -> Speaker {
        guard let user = req.auth.get(User.self) else {
            req.logger.info("GET /speakers/:id: Cannot get user from request.")
            throw Abort(.internalServerError)
        }
        guard let speaker = try await Speaker.find(req.parameters.get("speakerId"), on: req.db) else {
            throw Abort(.notFound)
        }
        if try user.requireID().uuidString != speaker.user.requireID().uuidString {
            throw Abort(.unauthorized)
        }
        return speaker
    }

    func createNewSpeaker(req: Request) async throws -> Speaker {
        guard let user = req.auth.get(User.self) else {
            req.logger.info("POST /speakers: Cannot get user from request.")
            throw Abort(.internalServerError)
        }
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

    func updateSpeaker(req: Request) async throws -> Speaker {
        guard let user = req.auth.get(User.self) else {
            req.logger.info("PUT /speakers/:id: Cannot get user from request.")
            throw Abort(.internalServerError)
        }
        guard let speakerId = req.parameters.get("speakerId") else {
            req.logger.info("PUT /speakers/:id: Cannot get speakerId from request.")
            throw Abort(.notAcceptable)
        }
        guard let speaker = try await Speaker.find(UUID(speakerId), on: req.db) else {
            req.logger.info("PUT /speakers/:id: Cannot find speaker with ID \(speakerId).")
            throw Abort(.notFound)
        }
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
}


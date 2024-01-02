import Vapor

struct SpeakerController: RouteCollection {

    let speakerService: SpeakerService

    func boot(routes: RoutesBuilder) throws {
        let speakers = routes.grouped("speakers")
        speakers.get(use: getUserSpeakers)
        speakers.group(":speakerId") { speaker in
            speaker.get(use: getById)
            speaker.put(use: updateSpeaker)
            speaker.delete(use: deleteSpeaker)
        }
        speakers.post(use: createNewSpeaker)
    }

    func getUserSpeakers(req: Request) async throws -> [Speaker] {
        guard let user = req.auth.get(User.self) else {
            req.logger.info("GET /speakers: Cannot get user from request.")
            throw Abort(.internalServerError)
        }
        return try await speakerService.getUserSpeakers(req: req, user: user)
    }

    func getById(req: Request) async throws -> Speaker {
        guard let user = req.auth.get(User.self) else {
            req.logger.info("GET /speakers/:id: Cannot get user from request.")
            throw Abort(.internalServerError)
        }
        guard let speakerId = req.parameters.get("speakerId") else {
            req.logger.info("GET /speakers/:id: Cannot get speakerId from request.")
            throw Abort(.notAcceptable)
        }
        return try await speakerService.getSpeakerById(req: req, user: user, speakerId: speakerId)
    }

    func createNewSpeaker(req: Request) async throws -> Speaker {
        guard let user = req.auth.get(User.self) else {
            req.logger.info("POST /speakers: Cannot get user from request.")
            throw Abort(.internalServerError)
        }
        return try await speakerService.createNewSpeaker(req: req, user: user)
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
        return try await speakerService.updateUserSpeaker(req: req, user: user, speakerId: speakerId)
    }

    func deleteSpeaker(req: Request) async throws -> HTTPStatus {
        guard let user = req.auth.get(User.self) else {
            req.logger.info("DELETE /speakers/:id: Cannot get user from request.")
            throw Abort(.internalServerError)
        }
        guard let speakerId = req.parameters.get("speakerId") else {
            req.logger.info("DELETE /speakers/:id: Cannot get speakerId from request.")
            throw Abort(.notAcceptable)
        }
        return try await speakerService.deleteUserSpeaker(req: req, user: user, speakerId: speakerId)
    }
}


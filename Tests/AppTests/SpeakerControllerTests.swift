@testable import App
import XCTVapor
import Fluent

final class SpeakerControllerTests: XCTestCase {

    fileprivate static let app: Application = Application(.testing)

    fileprivate static var userTimId = UUID()
    fileprivate static var userTimToken = ""
    fileprivate static var speakerIds: [String] = []

    fileprivate static var adminId = UUID()
    fileprivate static var adminToken = ""
    fileprivate static var adminSpeakerId = ""

    override class func setUp() {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            try await configure(app)

            let userTim = User(
                userType: .user,
                username: "tim",
                email: "tim@example.com",
                name: "Tim",
                passwordHash: "password")
            try await userTim.create(on: app.db)
            userTimId = try userTim.requireID()
            userTimToken = try app.jwt.signers.sign(SessionToken(userId: userTimId))
            try await Token(token: userTimToken, userId: userTimId).create(on: app.db)

            let speaker1 = Speaker(userId: userTimId, name: "Speaker1")
            try await speaker1.create(on: app.db)
            let speaker2 = Speaker(userId: userTimId, name: "Speaker2")
            try await speaker2.create(on: app.db)
            let speaker3 = Speaker(userId: userTimId, name: "Speaker3")
            try await speaker3.create(on: app.db)
            speakerIds = try [speaker1.requireID().uuidString, speaker2.requireID().uuidString, speaker3.requireID().uuidString]

            let admin = User(
                userType: .admin,
                username: "admin",
                email: "admin@example.com",
                name: "Admin",
                passwordHash: "password")
            try await admin.create(on: app.db)
            adminId = try admin.requireID()
            adminToken = try app.jwt.signers.sign(SessionToken(userId: adminId))
            try await Token(token: adminToken, userId: adminId).create(on: app.db)

            let adminSpeaker = Speaker(userId: adminId, name: "AdminSpeaker")
            try await adminSpeaker.create(on: app.db)
            adminSpeakerId = try adminSpeaker.requireID().uuidString

            semaphore.signal()
        }
        semaphore.wait()
        super.setUp()
    }

    override class func tearDown() {
        app.shutdown()
        super.tearDown()
    }

    func testGetUserSpeakersByUser() async throws {
        try SpeakerControllerTests.app.test(.GET, "speakers",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.userTimToken)
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertNoThrow {
                    let speakers = try res.content.decode([Speaker].self)
                    XCTAssertTrue(speakers.count != 0)
                    for speaker in speakers {
                        try XCTAssertTrue(SpeakerControllerTests.speakerIds.contains(speaker.requireID().uuidString))
                    }
                }

        })
    }

    func testGetUserSpeakersByAdmin() async throws {
        let userId = SpeakerControllerTests.userTimId.uuidString
        try SpeakerControllerTests.app.test(.GET, "users/\(userId)/speakers",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.adminToken)
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertNoThrow {
                    let speakers = try res.content.decode([Speaker].self)
                    XCTAssertTrue(speakers.count != 0)
                    for speaker in speakers {
                        try XCTAssertTrue(SpeakerControllerTests.speakerIds.contains(speaker.requireID().uuidString))
                    }
                }
        })
    }

    func testGetAdminSpeakerByUser() async throws {
        let userId = SpeakerControllerTests.adminId.uuidString
        try SpeakerControllerTests.app.test(.GET, "users/\(userId)/speakers",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.userTimToken)
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testGetUserSpeakersUnauthorized() async throws {
        let userId = SpeakerControllerTests.userTimId.uuidString
        try SpeakerControllerTests.app.test(.GET, "users/\(userId)/speakers",
            afterResponse: { res in
                XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testUpdateUserSpeakerByUserWithCorrectRequest() async throws {
        let speakerId = SpeakerControllerTests.speakerIds.first!
        try SpeakerControllerTests.app.test(.PUT, "speakers/\(speakerId)",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.userTimToken)
                try req.content.encode(["name": "newSpeakerName"])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertNoThrow {
                    let speaker = try res.content.decode(Speaker.self)
                    XCTAssertEqual(speaker.name, "newSpeakerName")
                }
        })
    }

    func testUpdateUserSpeakerByUserWithBadRequest() async throws {
        let speakerId = SpeakerControllerTests.speakerIds.first!
        try SpeakerControllerTests.app.test(.PUT, "speakers/\(speakerId)",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.userTimToken)
                try req.content.encode(["notName": "newSpeakerName"])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpdateUserSpeakerByAdminWithCorrectRequest() async throws {
        let speakerId = SpeakerControllerTests.speakerIds.first!
        try SpeakerControllerTests.app.test(.PUT, "speakers/\(speakerId)",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.adminToken)
                try req.content.encode(["name": "newSpeakerName"])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertNoThrow {
                    let speaker = try res.content.decode(Speaker.self)
                    XCTAssertEqual(speaker.name, "newSpeakerName")
                }
        })
    }

    func testUpdateUserSpeakerByAdminWithBadRequest() async throws {
        let speakerId = SpeakerControllerTests.speakerIds.first!
        try SpeakerControllerTests.app.test(.PUT, "speakers/\(speakerId)",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.adminToken)
                try req.content.encode(["notName": "newSpeakerName"])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testUpdateAdminSpeakerByUserWithCorrectRequest() async throws {
        let speakerId = SpeakerControllerTests.adminSpeakerId
        try SpeakerControllerTests.app.test(.PUT, "speakers/\(speakerId)",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.userTimToken)
                try req.content.encode(["name": "newSpeakerName"])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testUpdateAdminSpeakerByUserWithBadRequest() async throws {
        let speakerId = SpeakerControllerTests.adminSpeakerId
        try SpeakerControllerTests.app.test(.PUT, "speakers/\(speakerId)",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.userTimToken)
                try req.content.encode(["notName": "newSpeakerName"])
        }, afterResponse: { res in
                XCTAssertTrue(res.status == .unauthorized || res.status == .badRequest)
        })
    }

    func testUpdateUserSpeakerUnauthorizedWithCorrectRequest() async throws {
        let speakerId = SpeakerControllerTests.speakerIds.first!
        try SpeakerControllerTests.app.test(.PUT, "speakers/\(speakerId)",
            beforeRequest: { req in
                try req.content.encode(["name": "newSpeakerName"])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testUpdateUserSpeakerUnauthorizedWithBadRequest() async throws {
        let speakerId = SpeakerControllerTests.speakerIds.first!
        try SpeakerControllerTests.app.test(.PUT, "speakers/\(speakerId)",
            beforeRequest: { req in
                try req.content.encode(["notName": "newSpeakerName"])
        }, afterResponse: { res in
                XCTAssertTrue(res.status == .unauthorized || res.status == .badRequest)
        })
    }

    func testCreateUserSpeakerByUserWithCorrectRequest() async throws {
        try SpeakerControllerTests.app.test(.POST, "speakers",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.userTimToken)
                try req.content.encode(["name": "speakerTestUser"])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertNoThrow {
                    let speaker = try res.content.decode(Speaker.self)
                    XCTAssertEqual(speaker.name, "speakerTestUser")
                }
        })
    }

    func testCreateUserSpeakerByUserWithBadRequest() async throws {
        try SpeakerControllerTests.app.test(.POST, "speakers",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.userTimToken)
                try req.content.encode(["notName": "speakerTestUser"])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testCreateUserSpeakerByAdminWithCorrectRequest() async throws {
        let userId = SpeakerControllerTests.userTimId.uuidString
        try SpeakerControllerTests.app.test(.POST, "users/\(userId)/speakers",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.adminToken)
                try req.content.encode(["name": "speakerTestAdmin"])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertNoThrow {
                    let speaker = try res.content.decode(Speaker.self)
                    XCTAssertEqual(speaker.name, "speakerTestAdmin")
                }
        })
    }

    func testCreateUserSpeakerByAdminWithBadRequest() async throws {
        let userId = SpeakerControllerTests.userTimId.uuidString
        try SpeakerControllerTests.app.test(.POST, "users/\(userId)/speakers",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.adminToken)
                try req.content.encode(["notName": "speakerTestAdmin"])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testCreateAdminSpeakerByUserWithCorrectRequest() async throws {
        let userId = SpeakerControllerTests.adminId.uuidString
        try SpeakerControllerTests.app.test(.POST, "users/\(userId)/speakers",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.userTimToken)
                try req.content.encode(["name": "speakerTestAdmin"])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testCreateAdminSpeakerByUserWithBadRequest() async throws {
        let userId = SpeakerControllerTests.adminId.uuidString
        try SpeakerControllerTests.app.test(.POST, "users/\(userId)/speakers",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.userTimToken)
                try req.content.encode(["notName": "speakerTestAdmin"])
        }, afterResponse: { res in
                XCTAssertTrue(res.status == .badRequest || res.status == .unauthorized)
        })
    }

    func testCreateUserSpeakerUnauthorizedWithCorrectRequest() async throws {
        let userId = SpeakerControllerTests.userTimId.uuidString
        try SpeakerControllerTests.app.test(.POST, "users/\(userId)/speakers",
            beforeRequest: { req in
                try req.content.encode(["name": "newSpeakerName"])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testCreateUserSpeakerUnauthorizedWithBadRequest() async throws {
        let userId = SpeakerControllerTests.userTimId.uuidString
        try SpeakerControllerTests.app.test(.POST, "users/\(userId)/speakers",
            beforeRequest: { req in
                try req.content.encode(["name": "newSpeakerName"])
        }, afterResponse: { res in
                XCTAssertTrue(res.status == .unauthorized || res.status == .badRequest)
        })
    }

    func testDeleteUserSpeakerByUser() async throws {
        let speakerId = SpeakerControllerTests.speakerIds.last!
        try SpeakerControllerTests.app.test(.DELETE, "speakers/\(speakerId)",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.userTimToken)
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
        })
    }

    func testDeleteUserSpeakerByAdmin() async throws {
        let speakerId = SpeakerControllerTests.speakerIds[1]
        try SpeakerControllerTests.app.test(.DELETE, "speakers/\(speakerId)",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.adminToken)
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
        })
    }

    func testDeleteAdminSpeakerByUser() async throws {
        let speakerId = SpeakerControllerTests.adminSpeakerId
        try SpeakerControllerTests.app.test(.DELETE, "speakers/\(speakerId)",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: SpeakerControllerTests.userTimToken)
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .unauthorized)
        })
    }

    func testDeleteUserSpeakerUnauthorized() async throws {
        let speakerId = SpeakerControllerTests.speakerIds.first!
        try SpeakerControllerTests.app.test(.DELETE, "speakers/\(speakerId)",
            afterResponse: { res in
                XCTAssertEqual(res.status, .unauthorized)
        })
    }
}

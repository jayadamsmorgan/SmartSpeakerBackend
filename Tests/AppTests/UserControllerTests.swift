@testable import App
import XCTVapor
import Fluent

final class UserControllerTests: XCTestCase {

    fileprivate static let app: Application = Application(.testing)

    fileprivate static var timUserId = UUID()
    fileprivate static var timUserToken = ""

    fileprivate static var adminUserId = UUID()
    fileprivate static var adminUserToken = ""

    func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }

    override class func setUp() {
        super.setUp()
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            // App configuration
            try await configure(app)

            // Creating user "Tim" with userType USER
            let tim = User(
                userType: .user,
                username: "tim",
                email: "tim@example.com",
                name: "Tim",
                passwordHash: "timPasswordHash")
            try await tim.create(on: app.db)
            timUserId = try tim.requireID()
            timUserToken = try app.jwt.signers.sign(SessionToken(userId: timUserId))
            try await Token(token: timUserToken, userId: timUserId).create(on: app.db)

            // Creating user "Admin" with userType ADMIN
            let admin = User(
                userType: .admin,
                username: "admin",
                email: "admin@example.com",
                name: "Admin",
                passwordHash: "adminPasswordHash")
            try await admin.save(on: app.db)
            adminUserId = try admin.requireID()
            adminUserToken = try app.jwt.signers.sign(SessionToken(userId: adminUserId))
            try await Token(token: adminUserToken, userId: adminUserId).create(on: app.db)

            // Async task complete
            semaphore.signal()
        }
        semaphore.wait()
    }

    override class func tearDown() {
        app.shutdown()
        super.tearDown()
    }

    func testGetUserMakingRequestWhenAuthenticated() async throws {
        let app = UserControllerTests.app

        // Get current user info
        try app.test(.GET, "users",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: UserControllerTests.timUserToken)
            }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertNoThrow {
                    let user = try res.content.decode(UserInfoDTO.self)
                    XCTAssertNotNil(user)
                    XCTAssertEqual(user.username, "tim")
                    XCTAssertEqual(user.email, "tim@example.com")
                }
            })
    }

    func testGetUserMakingRequestWhenNotAuthenticated() async throws {
        let app = UserControllerTests.app

        // Get current user info
        try app.test(.GET, "users",
            afterResponse: { res in
                XCTAssertEqual(res.status, .unauthorized)
            })
    }

    func testUpdateUserWhenAuthenticatedAndCorrectRequest() async throws {
        let app = UserControllerTests.app

        let newName = randomString(length: 10)

        // Update user
        try app.test(.PUT, "users",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: UserControllerTests.timUserToken)
                let updateDTO = UserUpdateDTO(name: newName, username: "tim", email: "tim@example.com")
                try req.content.encode(updateDTO)
            }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertNoThrow {
                    let user = try res.content.decode(UserInfoDTO.self)
                    XCTAssertNotNil(user)
                    XCTAssertEqual(user.name, newName)
                }
            })
    }

    func testUpdateUserWhenAuthenticatedAndBadRequest() async throws {
        let app = UserControllerTests.app

        let newName = randomString(length: 10)

        // Update user
        try app.test(.PUT, "users",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: UserControllerTests.timUserToken)
                try req.content.encode([
                    "notName" : newName
                ])
            }, afterResponse: { res in
                XCTAssertEqual(res.status, .badRequest)
            })
    }

    func testUpdateUserWhenNotAuthenticatedAndCorrectRequest() async throws {
        let app = UserControllerTests.app

        let newName = randomString(length: 10)

        // Update user
        try app.test(.PUT, "users",
            beforeRequest: { req in
                try req.content.encode([
                    "name" : newName
                ])
            }, afterResponse: { res in
                XCTAssertEqual(res.status, .unauthorized)
            })
    }

    func testUpdateUserWhenNotAuthenticatedAndBadRequest() async throws {
        let app = UserControllerTests.app

        let newName = randomString(length: 10)

        // Update user
        try app.test(.PUT, "users",
            beforeRequest: { req in
                try req.content.encode([
                    "notName" : newName
                ])
            }, afterResponse: { res in
                XCTAssertEqual(res.status, .unauthorized)
            })
    }
}

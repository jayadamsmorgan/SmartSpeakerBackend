@testable import App
import XCTVapor
import Fluent

final class AuthControllerTests: XCTestCase {

    fileprivate static let app: Application = Application(.testing)

    override class func setUp() {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            try await configure(app)

            let user = User(
                userType: .user,
                username: "tim",
                email: "tim@example.com",
                name: "Tim",
                passwordHash: "password")
            try await user.create(on: app.db)
            semaphore.signal()
        }
        semaphore.wait()
        super.setUp()
    }

    override class func tearDown() {
        app.shutdown()
        super.tearDown()
    }

    func testRegisterWhenUserExistsAndCorrectRequest() async throws {
        let app = AuthControllerTests.app

        try app.test(.POST, "auth/register",
            beforeRequest: { req in
                try req.content.encode([
                    "username" : "tim",
                    "email" : "tim@example.com",
                    "password" : "password"
                ])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .notAcceptable)
        })
    }

    func testRegisterWhenUserDoesNotExistAndCorrectRequest() async throws {
        let app = AuthControllerTests.app

        try app.test(.POST, "auth/register",
            beforeRequest: { req in
                try req.content.encode([
                    "username" : "jake",
                    "email" : "jake@example.com",
                    "password" : "password"
                ])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                var registrationToken: ClientTokenReponse?
                XCTAssertNoThrow(registrationToken = try res.content.decode(ClientTokenReponse.self))
                let unwrappedToken = try XCTUnwrap(registrationToken)
                XCTAssertNotNil(unwrappedToken.token)
        })
    }

    func testRegisterWhenBadRequest() async throws {
        let app = AuthControllerTests.app

        try app.test(.POST, "auth/register",
            beforeRequest: { req in
                try req.content.encode([
                    "notUsername" : "jake",
                    "notEmail" : "jake@example.com",
                    "notPassword" : "password"
                ])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testAuthenticateWithEmailWhenUserExistsAndCorrectRequest() async throws {
        let app = AuthControllerTests.app

        try app.test(.POST, "auth/authenticate",
            beforeRequest: { req in
                try req.content.encode([
                    "email" : "tim@example.com",
                    "password" : "password"
                ])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                var token: ClientTokenReponse?
                XCTAssertNoThrow(token = try res.content.decode(ClientTokenReponse.self))
                let unwrappedToken = try XCTUnwrap(token)
                XCTAssertNotNil(unwrappedToken.token)
        })
    }

    func testAuthenticateWithUsernameWhenUserExistsAndCorrectRequest() async throws {
        let app = AuthControllerTests.app

        try app.test(.POST, "auth/authenticate",
            beforeRequest: { req in
                try req.content.encode([
                    "username" : "tim",
                    "password" : "password"
                ])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                var token: ClientTokenReponse?
                XCTAssertNoThrow(token = try res.content.decode(ClientTokenReponse.self))
                let unwrappedToken = try XCTUnwrap(token)
                XCTAssertNotNil(unwrappedToken.token)
        })
    }

    func testAuthenticateWhenUserExistsAndIncorrectPassword() async throws {
        let app = AuthControllerTests.app

        try app.test(.POST, "auth/authenticate",
            beforeRequest: { req in
                try req.content.encode([
                    "username" : "tim",
                    "password" : "incorrectPassword"
                ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .forbidden)
        })
    }

    func testAuthenticateWhenBadRequest() async throws {
        let app = AuthControllerTests.app

        try app.test(.POST, "auth/authenticate",
            beforeRequest: { req in
                try req.content.encode([
                    "notEmail" : "tim@example.com",
                    "notPassword" : "password"
                ])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .badRequest)
        })
    }

    func testAuthenticateWhenUserDoesNotExistAndCorrectRequest() async throws {
        let app = AuthControllerTests.app

        try app.test(.POST, "auth/authenticate",
            beforeRequest: { req in
                try req.content.encode([
                    "email" : "jason@example.com",
                    "password" : "password"
                ])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .notFound)
        })
    }
}

@testable import App
import XCTVapor

final class AuthControllerTests: XCTestCase {

    func testAuthenticateWithRegister() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        var registrationToken: ClientTokenReponse?

        // Register
        try app.test(.POST, "auth/register",
            beforeRequest: { req in
                try req.content.encode([
                    "username" : "tim",
                    "email" : "tim@example.com",
                    "password" : "password"
                ])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertNoThrow(registrationToken = try res.content.decode(ClientTokenReponse.self))
                let unwrappedToken = try XCTUnwrap(registrationToken)
                XCTAssertNotNil(unwrappedToken.token)
        })

        // Authenticate with username
        try app.test(.POST, "auth/authenticate",
            beforeRequest: { req in
                try req.content.encode([
                    "username" : "tim",
                    "password" : "password"
                ])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                var newToken: ClientTokenReponse?
                XCTAssertNoThrow(newToken = try res.content.decode(ClientTokenReponse.self))
                let unwrappedToken = try XCTUnwrap(newToken)
                XCTAssertNotNil(unwrappedToken.token)
                XCTAssertEqual(unwrappedToken.token, registrationToken?.token)
        })

        // Authenticate with email
        try app.test(.POST, "auth/authenticate",
            beforeRequest: { req in
                try req.content.encode([
                    "email" : "tim@example.com",
                    "password" : "password"
                ])
        }, afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                var newToken: ClientTokenReponse?
                XCTAssertNoThrow(newToken = try res.content.decode(ClientTokenReponse.self))
                let unwrappedToken = try XCTUnwrap(newToken)
                XCTAssertNotNil(unwrappedToken.token)
                XCTAssertEqual(unwrappedToken.token, registrationToken?.token)
        })
    }

}

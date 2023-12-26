import Vapor

final class AuthService {

    init() { }

    static func authenticate(with authDTO: AuthDTO) async -> AuthResponse {
        if let password = authDTO.password {

        }
        return AuthResponse(error: "Not yet implemented")
    }

    static func register(with authDTO: AuthDTO) async -> AuthResponse {

        return AuthResponse(error: "Not yet implemented")
    }
}

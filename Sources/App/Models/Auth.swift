import Vapor

struct AuthDTO: Content {

    let phoneNumber: String?
    let email: String?
    let username: String?
    
    let password: String?

    init() {
        self.phoneNumber = nil
        self.email = nil
        self.username = nil
        self.password = nil
    }

}

struct AuthResponse: Content {
    let error: String?
    let token: String?

    init(error: String) {
        self.error = error
        self.token = nil
    }

    init(token: String) {
        self.token = token
        self.error = nil
    }
}

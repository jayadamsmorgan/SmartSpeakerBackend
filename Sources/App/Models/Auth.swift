import Vapor

struct AuthDTO: Content {

    let email: String?
    let username: String?
    
    let password: String?

    init() {
        self.email = nil
        self.username = nil
        self.password = nil
    }

}


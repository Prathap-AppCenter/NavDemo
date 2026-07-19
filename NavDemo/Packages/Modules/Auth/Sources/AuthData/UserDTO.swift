import Foundation
import AuthDomain

struct UserDTO: Decodable {
    let id: String
    let email: String
    let name: String
    func toDomain() -> User { User(id: id, email: email, name: name) }
}

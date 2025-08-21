import Foundation

struct User: Codable, Equatable {
    let id: UUID
    var email: String?
    var name: String?
    var isGuest: Bool
    var avatarData: Data?
    
    init(email: String? = nil, name: String? = nil, isGuest: Bool = false, avatarData: Data? = nil) {
        self.id = UUID()
        self.email = email
        self.name = name
        self.isGuest = isGuest
        self.avatarData = avatarData
    }
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.email == rhs.email && lhs.name == rhs.name && lhs.isGuest == rhs.isGuest && lhs.avatarData == rhs.avatarData
    }
} 
import Foundation
import FirebaseFirestore

struct Child: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var tokenBalance: Int
    var rfidTag: String?
    var linkedUserId: String? // <--- New: Stores the Child's Authentication UID
    
    static func == (lhs: Child, rhs: Child) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// New struct for the global "invitations" collection
struct Invitation: Codable {
    @DocumentID var id: String? // The 6-digit code
    var parentId: String
    var childId: String
    var createdAt: Date
}

// New struct to store on the User's profile to know if they are a Child
struct UserProfile: Codable {
    @DocumentID var id: String?
    var linkedParentId: String?
    var linkedChildId: String?
}

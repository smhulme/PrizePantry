import Foundation
import FirebaseFirestore

struct Child: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var tokenBalance: Int
    var rfidTag: String?
    var linkedUserId: String?
    
    // ✅ These must exist for ChildSettingsView to access them
    var unlockCost: Int?
    var unlockDuration: Int?
    
    static func == (lhs: Child, rhs: Child) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Invitation: Codable {
    @DocumentID var id: String?
    var parentId: String
    var childId: String
    var createdAt: Date
}

struct UserProfile: Codable {
    @DocumentID var id: String?
    var linkedParentId: String?
    var linkedChildId: String?
}

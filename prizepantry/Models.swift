import Foundation
import FirebaseFirestore

struct Child: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var tokenBalance: Int
    var rfidTag: String? // <--- Store the tag ID here
    
    // This tells Swift: "Two children are the same if their IDs are the same"
    static func == (lhs: Child, rhs: Child) -> Bool {
        return lhs.id == rhs.id
    }

    // This creates a unique "fingerprint" for the picker using the ID
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

import Foundation
import FirebaseFirestore

struct Child: Identifiable, Codable {
    // @DocumentID allows Firestore to manage the unique ID string automatically
    @DocumentID var id: String?
    var name: String
    var tokenBalance: Int
}

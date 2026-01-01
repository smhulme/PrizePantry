import Foundation
import FirebaseFirestore
import FirebaseAuth

class ChildViewModel: ObservableObject {
    @Published var children: [Child] = []
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    // Helper to get the current secure User ID
    private var userId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    init() {
        fetchData()
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func fetchData() {
        // Ensure we have a user ID. If not, stop.
        guard let uid = userId else {
            print("No user logged in")
            return
        }
        
        // Listen to: users -> {uid} -> children
        let ref = db.collection("users").document(uid).collection("children")
        
        listenerRegistration = ref.addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("No documents")
                return
            }
            
            self.children = documents.compactMap { queryDocumentSnapshot -> Child? in
                return try? queryDocumentSnapshot.data(as: Child.self)
            }
        }
    }
    
    func addChild(name: String) {
        guard let uid = userId else { return }
        
        let newChild = Child(name: name, tokenBalance: 0)
        do {
            try db.collection("users").document(uid).collection("children").addDocument(from: newChild)
        } catch {
            print("Error adding child: \(error)")
        }
    }
    
    func updateTokens(child: Child, amount: Int) {
        guard let uid = userId, let childId = child.id else { return }
        
        db.collection("users").document(uid).collection("children").document(childId).updateData([
            "tokenBalance": amount
        ])
    }
    
    func deleteChild(at offsets: IndexSet) {
        guard let uid = userId else { return }
        
        offsets.map { children[$0] }.forEach { child in
            if let id = child.id {
                db.collection("users").document(uid).collection("children").document(id).delete()
            }
        }
    }
    
    func assignTagToChild(child: Child, tagID: String) {
        guard let uid = userId, let childId = child.id else { return }
        
        db.collection("users").document(uid).collection("children").document(childId).updateData([
            "rfidTag": tagID
        ]) { error in
            if let error = error {
                print("Error assigning tag: \(error)")
            } else {
                print("Successfully assigned tag \(tagID) to \(child.name)")
            }
        }
    }
    
    // Optional: Sign out function to be called from UI
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.children = [] // Clear data on sign out
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ChildViewModel: ObservableObject {
    // Parent Mode Data
    @Published var children: [Child] = []
    
    // Child Mode Data
    @Published var isChildAccount: Bool = false
    @Published var linkedChildProfile: Child?
    
    // UI State
    @Published var invitationCode: String?
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var childrenListener: ListenerRegistration?
    private var childProfileListener: ListenerRegistration?
    
    private var userId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    init() {
        checkUserRole()
    }
    
    deinit {
        childrenListener?.remove()
        childProfileListener?.remove()
    }
    
    // MARK: - Startup Logic
    func checkUserRole() {
        guard let uid = userId else { return }
        
        // Check if this user has a "UserProfile" document indicating they are a child
        let docRef = db.collection("users").document(uid)
        
        docRef.getDocument { document, error in
            if let document = document, document.exists,
               let profile = try? document.data(as: UserProfile.self),
               let parentId = profile.linkedParentId,
               let childId = profile.linkedChildId {
                
                // USER IS A CHILD
                DispatchQueue.main.async { self.isChildAccount = true }
                self.listenToLinkedChild(parentId: parentId, childId: childId)
                
            } else {
                // USER IS A PARENT (Default)
                DispatchQueue.main.async { self.isChildAccount = false }
                self.fetchParentData()
            }
        }
    }

    // MARK: - Parent Logic
    func fetchParentData() {
        guard let uid = userId else { return }
        let ref = db.collection("users").document(uid).collection("children")
        
        childrenListener = ref.addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else { return }
            self.children = documents.compactMap { try? $0.data(as: Child.self) }
        }
    }
    
    func addChild(name: String) {
        guard let uid = userId else { return }
        let newChild = Child(name: name, tokenBalance: 0)
        try? db.collection("users").document(uid).collection("children").addDocument(from: newChild)
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
        db.collection("users").document(uid).collection("children").document(childId).updateData(["rfidTag": tagID])
    }
    
    // MARK: - Invitation System (Parent Side)
    func generateInviteCode(for child: Child) {
        guard let uid = userId, let childId = child.id else { return }
        
        // Generate a random 6-digit code
        let code = String(Int.random(in: 100000...999999))
        
        let invite = Invitation(parentId: uid, childId: childId, createdAt: Date())
        
        do {
            try db.collection("invitations").document(code).setData(from: invite)
            DispatchQueue.main.async { self.invitationCode = code }
        } catch {
            print("Error creating invite: \(error)")
        }
    }

    // MARK: - Linking Logic (Child Side)
    func redeemInviteCode(code: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("invitations").document(code).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let parentId = data["parentId"] as? String,
               let childId = data["childId"] as? String {
                
                // 1. Write the child's UID into the PARENT'S document
                self.db.collection("users").document(parentId)
                    .collection("children").document(childId)
                    .updateData(["linkedUserId": uid]) { error in
                        if let error = error {
                            print("Failed to link to parent: \(error.localizedDescription)")
                        }
                    }
                
                // 2. Create the child's own profile doc so they know who their parent is
                let profileData: [String: Any] = [
                    "linkedParentId": parentId,
                    "linkedChildId": childId
                ]
                self.db.collection("users").document(uid).setData(profileData)
                
                // 3. Cleanup
                self.db.collection("invitations").document(code).delete()
                self.checkUserRole()
            }
        }
    }
    
    // MARK: - Child Logic
    func listenToLinkedChild(parentId: String, childId: String) {
        // 1. Initial log to confirm the function is actually running
        print("DEBUG [TokenTime]: Starting listener for Parent: \(parentId), ChildDoc: \(childId)")
        
        let ref = db.collection("users").document(parentId).collection("children").document(childId)
        
        childProfileListener = ref.addSnapshotListener { document, error in
            // 2. Log any Permission or Network errors
            if let error = error {
                print("DEBUG [TokenTime]: Firestore Error: \(error.localizedDescription)")
                print("DEBUG [TokenTime]: Check if your Rules allow read access to this specific path.")
                return
            }
            
            // 3. Log document status
            guard let document = document else {
                print("DEBUG [TokenTime]: Document is nil")
                return
            }
            
            if document.exists {
                print("DEBUG [TokenTime]: Success! Document found. Decoding data...")
                do {
                    self.linkedChildProfile = try document.data(as: Child.self)
                    print("DEBUG [TokenTime]: Child name is: \(self.linkedChildProfile?.name ?? "Unknown")")
                } catch {
                    print("DEBUG [TokenTime]: Decoding Error: Your Swift 'Child' model might not match your Firestore fields exactly. Error: \(error)")
                }
            } else {
                print("DEBUG [TokenTime]: Document does not exist at this path. Verify IDs in your 'users' collection.")
            }
        }
    }
    
}

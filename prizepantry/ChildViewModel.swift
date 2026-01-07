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
    @Published var settingsUnlockCode: String? // NEW: For admin configuration
    @Published var errorMessage: String?
    
    // Internal State
    private var db = Firestore.firestore()
    private var childrenListener: ListenerRegistration?
    private var childProfileListener: ListenerRegistration?
    
    private var currentParentId: String?
    
    private var userId: String?  {
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
        
        let docRef = db.collection("users").document(uid)
        
        docRef.getDocument { document, error in
            if let document = document, document.exists,
               let profile = try? document.data(as: UserProfile.self),
               let parentId = profile.linkedParentId,
               let childId = profile.linkedChildId {
                
                DispatchQueue.main.async {
                    self.isChildAccount = true
                    self.currentParentId = parentId
                }
                self.listenToLinkedChild(parentId: parentId, childId: childId)
                
            } else {
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
    
    // MARK: - Shared / Token Logic
    func updateTokens(child: Child, amount: Int) {
        let targetUid = isChildAccount ? currentParentId : userId
        
        guard let uid = targetUid, let childId = child.id else {
            print("Error: Could not determine document path.")
            return
        }
        
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
    
    // MARK: - Admin Access (NEW)
    func generateSettingsUnlockCode() {
        let code = String(Int.random(in: 100000...999999))
        let data: [String: Any] = [
            "createdAt": FieldValue.serverTimestamp(),
            "createdBy": Auth.auth().currentUser?.uid ?? "unknown"
        ]
        
        db.collection("unlock_codes").document(code).setData(data) { error in
            if let error = error {
                print("Error generating code: \(error)")
            } else {
                DispatchQueue.main.async { self.settingsUnlockCode = code }
            }
        }
    }
    
    func verifySettingsUnlockCode(code: String, completion: @escaping (Bool) -> Void) {
        let docRef = db.collection("unlock_codes").document(code)
        docRef.getDocument { document, _ in
            if let document = document, document.exists {
                docRef.delete() // One-time use
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    // MARK: - Invitation System
    func generateInviteCode(for child: Child) {
        guard let uid = userId, let childId = child.id else { return }
        let code = String(Int.random(in: 100000...999999))
        let invite = Invitation(parentId: uid, childId: childId, createdAt: Date())
        
        do {
            try db.collection("invitations").document(code).setData(from: invite)
            DispatchQueue.main.async { self.invitationCode = code }
        } catch {
            print("Error creating invite: \(error)")
        }
    }

    func redeemInviteCode(code: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("invitations").document(code).getDocument { snapshot, _ in
            if let data = snapshot?.data(),
               let parentId = data["parentId"] as? String,
               let childId = data["childId"] as? String {
                
                self.db.collection("users").document(parentId)
                    .collection("children").document(childId)
                    .updateData(["linkedUserId": uid])
                
                let profileData: [String: Any] = ["linkedParentId": parentId, "linkedChildId": childId]
                self.db.collection("users").document(uid).setData(profileData)
                self.db.collection("invitations").document(code).delete()
                self.checkUserRole()
            }
        }
    }
    
    // MARK: - Child Logic
    func listenToLinkedChild(parentId: String, childId: String) {
        let ref = db.collection("users").document(parentId).collection("children").document(childId)
        childProfileListener = ref.addSnapshotListener { document, error in
            if let error = error { return }
            guard let document = document, document.exists else { return }
            do {
                self.linkedChildProfile = try document.data(as: Child.self)
            } catch {
                print("Decoding Error: \(error)")
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.children = []
            self.linkedChildProfile = nil
            self.isChildAccount = false
            self.currentParentId = nil
            self.invitationCode = nil
            self.errorMessage = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Settings Logic
    func updateChildSettings(child: Child, cost: Int, duration: Int) {
        guard let uid = userId, let childId = child.id else { return }
        
        db.collection("users").document(uid).collection("children").document(childId).updateData([
            "unlockCost": cost,
            "unlockDuration": duration
        ]) { error in
            if let error = error {
                print("Error updating settings: \(error.localizedDescription)")
            }
        }
    }
}

import Foundation
import FirebaseFirestore

class ChildViewModel: ObservableObject {
    @Published var children: [Child] = []
    private var db = Firestore.firestore()
    
    init() {
        fetchData()
    }
    
    // This function listens for changes in real-time
    func fetchData() {
        db.collection("children").addSnapshotListener { (querySnapshot, error) in
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
        let newChild = Child(name: name, tokenBalance: 0)
        do {
            // Adds a new document to the "children" collection
            try db.collection("children").addDocument(from: newChild)
        } catch {
            print(error)
        }
    }
    
    func updateTokens(child: Child, amount: Int) {
        if let id = child.id {
            // Updates the specific child in the cloud
            db.collection("children").document(id).updateData([
                "tokenBalance": amount
            ])
        }
    }
    
    func deleteChild(at offsets: IndexSet) {
        offsets.map { children[$0] }.forEach { child in
            if let id = child.id {
                db.collection("children").document(id).delete()
            }
        }
    }
    // Add this to ChildViewModel.swift
    func assignTagToChild(child: Child, tagID: String) {
        guard let id = child.id else { return }
        
        // Update the specific child's document with the new tag
        db.collection("children").document(id).updateData([
            "rfidTag": tagID
        ]) { error in
            if let error = error {
                print("Error assigning tag: \(error)")
            } else {
                print("Successfully assigned tag \(tagID) to \(child.name)")
            }
        }
    }
}

import SwiftUI

struct ChildDashboardView: View {
    @ObservedObject var viewModel: ChildViewModel
    @StateObject var screenTimeManager = ScreenTimeManager.shared
    
    @State private var showUnlockAlert = false
    
    // Price Configuration
    let costPer30Minutes = 5
    
    var body: some View {
        VStack(spacing: 30) {
            if let child = viewModel.linkedChildProfile {
                // Header
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text(child.name).font(.title2).bold()
                        Text("\(child.tokenBalance) Tokens Available").foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                
                Divider()
                
                // --- BUY TIME INTERFACE ---
                VStack(spacing: 20) {
                    Text("Unlock Your Apps")
                        .font(.headline)
                    
                    // Unlock Button
                    Button {
                        purchaseTime(minutes: 30, cost: costPer30Minutes)
                    } label: {
                        VStack {
                            Text("30 Minutes")
                                .font(.title3).bold()
                            Text("\(costPer30Minutes) Tokens")
                                .badge(costPer30Minutes)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(child.tokenBalance >= costPer30Minutes ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(child.tokenBalance < costPer30Minutes)
                }
                .padding()
                
            } else {
                ProgressView("Loading Profile...")
            }
            
            Spacer()
            
            Button("Sign Out") {
                viewModel.signOut()
            }
            .tint(.red)
        }
        .onAppear {
            // Request permission as soon as the child dashboard loads.
            // This is required for the Shield to activate on this device.
            screenTimeManager.requestAuthorization()
        }
        .alert("Success!", isPresented: $showUnlockAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your apps have been unlocked for 30 minutes.")
        }
    }
    
    func purchaseTime(minutes: Int, cost: Int) {
        guard let child = viewModel.linkedChildProfile else { return }
        
        if child.tokenBalance >= cost {
            // 1. Deduct tokens via ViewModel (Firestore)
            // This ensures the token count goes down by the specific cost
            viewModel.updateTokens(child: child, amount: child.tokenBalance - cost)
            
            // 2. Unlock Apps
            screenTimeManager.unlockApps(forMinutes: minutes)
            
            showUnlockAlert = true
        }
    }
}

import SwiftUI

struct ChildDashboardView: View {
    @ObservedObject var viewModel: ChildViewModel
    @StateObject var screenTimeManager = ScreenTimeManager.shared
    
    @State private var showAdminCodeAlert = false
    @State private var adminCodeInput = ""
    @State private var isPickerPresented = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    let costPer30Minutes = 5
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                if let child = viewModel.linkedChildProfile {
                    HStack {
                        Image(systemName: "person.crop.circle.fill").resizable().frame(width: 50, height: 50).foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text(child.name).font(.title2).bold()
                            Text("\(child.tokenBalance) Tokens Available").foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    VStack(spacing: 20) {
                        Text("Unlock Your Apps").font(.headline)
                        Button { purchaseTime(minutes: 30, cost: costPer30Minutes) } label: {
                            Text("30 Minutes - \(costPer30Minutes) Tokens")
                                .frame(maxWidth: .infinity).padding()
                                .background(child.tokenBalance >= costPer30Minutes ? Color.green : Color.gray)
                                .foregroundColor(.white).cornerRadius(12)
                        }
                        .disabled(child.tokenBalance < costPer30Minutes)
                    }
                } else {
                    ProgressView("Loading Profile...")
                }
                
                Spacer()
                
                Button("Configure Blocked Apps") { showAdminCodeAlert = true }.font(.footnote).foregroundStyle(.gray)
                Button("Sign Out") { viewModel.signOut() }.tint(.red)
            }
            .onAppear { screenTimeManager.requestAuthorization() }
            .alert("Parent Access", isPresented: $showAdminCodeAlert) {
                TextField("6-digit Code", text: $adminCodeInput).keyboardType(.numberPad)
                Button("Verify") { verifyCode() }
                Button("Cancel", role: .cancel) { }
            }
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $screenTimeManager.activitySelection)
            .onChange(of: isPickerPresented) { _, isPresented in
                if !isPresented { screenTimeManager.saveSelectionAndLock() }
            }
            .alert(alertMessage, isPresented: $showAlert) { Button("OK", role: .cancel) { } }
        }
    }
    
    func verifyCode() {
        viewModel.verifySettingsUnlockCode(code: adminCodeInput) { success in
            if success { isPickerPresented = true } else {
                alertMessage = "Invalid Code"; showAlert = true
            }
        }
    }
    
    func purchaseTime(minutes: Int, cost: Int) {
        guard let child = viewModel.linkedChildProfile else { return }
        if child.tokenBalance >= cost {
            viewModel.updateTokens(child: child, amount: child.tokenBalance - cost)
            screenTimeManager.unlockApps(forMinutes: minutes)
            alertMessage = "Apps unlocked for 30 minutes!"; showAlert = true
        }
    }
}

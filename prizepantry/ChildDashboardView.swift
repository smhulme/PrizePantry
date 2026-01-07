import SwiftUI
import FamilyControls // Ensure this is imported for familyActivityPicker

struct ChildDashboardView: View {
    @ObservedObject var viewModel: ChildViewModel
    @StateObject var screenTimeManager = ScreenTimeManager.shared
    
    // Sheet States
    @State private var showSettingsSheet = false
    @State private var showAdminCodeAlert = false
    @State private var adminCodeInput = ""
    @State private var isPickerPresented = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    // Timer Logic
    @State private var timeRemaining: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var currentCost: Int {
        viewModel.linkedChildProfile?.unlockCost ?? 5
    }
    
    var currentDuration: Int {
        viewModel.linkedChildProfile?.unlockDuration ?? 30
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                if let child = viewModel.linkedChildProfile {
                    // Profile Header
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
                    
                    // --- TIMER DISPLAY ---
                    if timeRemaining > 0 {
                        VStack(spacing: 5) {
                            Text("Time Remaining")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text(formatTime(timeRemaining))
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundStyle(.blue)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(15)
                    } else {
                        Text("Apps are Locked")
                            .font(.headline)
                            .foregroundStyle(.gray)
                            .padding()
                    }
                    
                    // Unlock Buttons
                    VStack(spacing: 20) {
                        Text("Unlock Your Apps").font(.headline)
                        
                        Button {
                            purchaseTime(minutes: currentDuration, cost: currentCost)
                        } label: {
                            Text("Add \(currentDuration) Minutes - \(currentCost) Tokens")
                                .frame(maxWidth: .infinity).padding()
                                .background(child.tokenBalance >= currentCost ? Color.green : Color.gray)
                                .foregroundColor(.white).cornerRadius(12)
                        }
                        .disabled(child.tokenBalance < currentCost)
                    }
                } else {
                    ProgressView("Loading Profile...")
                }
                
                Spacer()
            }
            .navigationTitle("Dashboard") // Add a title for the toolbar to look correct
            .navigationBarTitleDisplayMode(.inline)
            // ---------------------------------------------------------
            // 1. ADD TOOLBAR WITH SETTINGS ICON
            // ---------------------------------------------------------
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showSettingsSheet = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            // ---------------------------------------------------------
            // 2. ADD SETTINGS SHEET
            // ---------------------------------------------------------
            .sheet(isPresented: $showSettingsSheet) {
                NavigationStack {
                    Form {
                        Section("Preferences") {
                            // The Toggle handles the user default binding directly via ScreenTimeManager
                            Toggle("Show Timer on Dynamic Island", isOn: $screenTimeManager.enableLiveActivity)
                                .tint(.blue)
                            
                            Text("When enabled, a timer will appear in the Dynamic Island and on the Lock Screen while your apps are unlocked.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Section("Account") {
                            Button("Configure Blocked Apps") {
                                showSettingsSheet = false // Close settings first
                                // Slight delay to allow sheet dismissal animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showAdminCodeAlert = true
                                }
                            }
                            
                            Button("Sign Out") {
                                showSettingsSheet = false
                                viewModel.signOut()
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    .navigationTitle("Settings")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showSettingsSheet = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .onAppear {
                screenTimeManager.requestAuthorization()
                updateTimer()
            }
            .onReceive(timer) { _ in
                updateTimer()
            }
            // Admin Code Alert (Triggered from Settings or directly if you kept the button)
            .alert("Parent Access", isPresented: $showAdminCodeAlert) {
                TextField("6-digit Code", text: $adminCodeInput).keyboardType(.numberPad)
                Button("Verify") { verifyCode() }
                Button("Cancel", role: .cancel) { }
            }
            // Family Activity Picker
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $screenTimeManager.activitySelection)
            .onChange(of: isPickerPresented) { _, isPresented in
                if !isPresented { screenTimeManager.saveSelectionAndLock() }
            }
            .alert(alertMessage, isPresented: $showAlert) { Button("OK", role: .cancel) { } }
        }
    }
    
    // ... Existing helper functions (updateTimer, formatTime, verifyCode, purchaseTime) ...
    func updateTimer() {
        if let endTime = screenTimeManager.sessionEndTime {
            let remaining = endTime.timeIntervalSinceNow
            timeRemaining = remaining > 0 ? remaining : 0
        } else {
            timeRemaining = 0
        }
    }
    
    func formatTime(_ totalSeconds: TimeInterval) -> String {
        let seconds = Int(totalSeconds) % 60
        let minutes = Int(totalSeconds) / 60
        return String(format: "%02d:%02d", minutes, seconds)
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
        }
    }
}

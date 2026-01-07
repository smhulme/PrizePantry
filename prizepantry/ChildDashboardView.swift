import SwiftUI
import DeviceActivity // Required for the Report view

struct ChildDashboardView: View {
    @ObservedObject var viewModel: ChildViewModel
    @StateObject var screenTimeManager = ScreenTimeManager.shared
    
    @State private var showAdminCodeAlert = false
    @State private var adminCodeInput = ""
    @State private var isPickerPresented = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    // ✅ NEW: Filter state for the Device Activity Report
    @State private var context: DeviceActivityReport.Context = .timeRemaining
    @State private var filter = DeviceActivityFilter(
        segment: .daily(during: DateInterval(start: Calendar.current.startOfDay(for: Date()), end: Date())),
        users: . all,
        devices: .init([. iPhone, .iPad])
    )
    
    // ✅ ADD THIS: Key to force report refresh
    @State private var reportRefreshKey = UUID()
    
    var currentCost: Int { viewModel.linkedChildProfile?.unlockCost ?? 5 }
    var currentDuration: Int { viewModel.linkedChildProfile?.unlockDuration ?? 30 }
    
    var body: some View {
        NavigationStack {
            VStack(spacing:  30) {
                if let child = viewModel.linkedChildProfile {
                    // Profile Header
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable().frame(width: 50, height:  50).foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text(child.name).font(.title2).bold()
                            Text("\(child.tokenBalance) Tokens").foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    // ✅ UPDATED: Usage Limit Status using the Live Report Extension
                    VStack(spacing: 10) {
                        if screenTimeManager.cumulativeAllowance > 0 {
                            // ✅ ADD . id() modifier to force refresh
                            DeviceActivityReport(context, filter: filter)
                                .frame(height: 120)
                                .id(reportRefreshKey) // Force refresh when this changes
                        } else {
                            // Empty state when no time is active
                            VStack(spacing:  8) {
                                Text("Apps Locked")
                                    .font(. headline)
                                    .foregroundStyle(.red)
                                Text("Spend tokens to unlock your apps.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(15)
                        }
                    }
                    .padding(. horizontal)
                    
                    // Interaction Section
                    VStack(spacing: 20) {
                        Button {
                            purchaseTime(minutes: currentDuration, cost: currentCost)
                        } label: {
                            VStack {
                                Text("Add \(currentDuration) Mins")
                                    .font(.headline)
                                Text("Cost: \(currentCost) Tokens")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(child.tokenBalance >= currentCost ?  Color.blue : Color.gray)
                            .foregroundColor(.white).cornerRadius(12)
                        }
                        .disabled(child.tokenBalance < currentCost)
                        
                        Text("Time stacks!  Adding more extends your daily limit.")
                            .font(. caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(. horizontal)
                } else {
                    ProgressView("Loading Profile...")
                }
                
                Spacer()
                
                // Admin / Setup Actions
                Button("Configure Blocked Apps") { showAdminCodeAlert = true }
                    .font(.footnote).foregroundStyle(.gray)
                
                Button("Sign Out") { viewModel.signOut() }
                    .tint(.red)
            }
            .onAppear {
                screenTimeManager.requestAuthorization()
                screenTimeManager.checkDateReset()
                updateReportFilter()
            }
            .alert("Parent Access", isPresented: $showAdminCodeAlert) {
                TextField("6-digit Code", text: $adminCodeInput).keyboardType(.numberPad)
                Button("Verify") { verifyCode() }
                Button("Cancel", role: .cancel) { }
            }
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $screenTimeManager.activitySelection)
            .onChange(of: isPickerPresented) { _, isPresented in
                if !isPresented {
                    screenTimeManager.saveSelectionAndLock()
                    updateReportFilter()
                    reportRefreshKey = UUID() // ✅ Refresh report
                }
            }
            .alert(alertMessage, isPresented: $showAlert) { Button("OK", role: .cancel) { } }
        }
    }
    
    // MARK: - Helpers
    
    /// Ensures the report is looking at the correct apps and the current day's usage
    func updateReportFilter() {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to:  startOfDay)!
        
        filter = DeviceActivityFilter(
            segment: .daily(during: DateInterval(start: startOfDay, end: endOfDay)),
            users: .all,
            devices: .init([.iPhone, . iPad]),
            applications: screenTimeManager.activitySelection.applicationTokens,
            categories: screenTimeManager.activitySelection.categoryTokens,
            webDomains: screenTimeManager.activitySelection.webDomainTokens
        )
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
            
            // Add the time
            screenTimeManager.addTime(minutes: minutes)
            
            // ✅ Force the report to refresh immediately
            reportRefreshKey = UUID()
            
            // ✅ Optional: Also update the filter to ensure it's current
            updateReportFilter()
        }
    }
}

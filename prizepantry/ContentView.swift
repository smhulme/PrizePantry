import SwiftUI
import FamilyControls // Import needed for the picker

struct ContentView: View {
    @StateObject var viewModel = ChildViewModel()
    @StateObject var screenTimeManager = ScreenTimeManager.shared // Access ScreenTimeManager
    
    // Binding to control the app's root login state
    @Binding var isLoggedIn: Bool
    
    @State private var showingAddChildSheet = false
    @State private var newChildName = ""
    @State private var selectedChildForInvite: Child?
    
    // State for the Family Activity Picker
    @State private var isPickerPresented = false

    var body: some View {
        // 1. CHECK MODE: If the user is linked as a child, show the read-only dashboard
        if viewModel.isChildAccount {
            ChildDashboardView(viewModel: viewModel)
        }
        else {
            NavigationStack {
                List {
                    // 2. CHECK MODE: If the parent has no children yet, show an option to join a family
                    if viewModel.children.isEmpty {
                        Section {
                             NavigationLink("Join an existing Family", destination: JoinFamilyView(viewModel: viewModel))
                        } footer: {
                            Text("If you are a child, enter the code provided by your parent.")
                        }
                    }

                    ForEach(viewModel.children) { child in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(child.name).font(.headline)
                                Text("\(child.tokenBalance) Tokens")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                
                                if child.linkedUserId != nil {
                                    Text("Linked to Apple ID")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                            Spacer()
                            
                            // Link Button (Key Icon) - Generates the 6-digit code
                            Button {
                                viewModel.generateInviteCode(for: child)
                                selectedChildForInvite = child
                            } label: {
                                Image(systemName: "key.fill").foregroundStyle(.orange)
                            }
                            .buttonStyle(.borderless)
                            .padding(.trailing, 10)
                            
                            // Token Controls
                            Button {
                                if child.tokenBalance > 0 {
                                    viewModel.updateTokens(child: child, amount: child.tokenBalance - 1)
                                }
                            } label: {
                                Image(systemName: "minus.circle").foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                            
                            Button {
                                viewModel.updateTokens(child: child, amount: child.tokenBalance + 1)
                            } label: {
                                Image(systemName: "plus.circle.fill").foregroundStyle(.green)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .onDelete(perform: viewModel.deleteChild)
                }
                .navigationTitle("Prize Pantry")
                .toolbar {
                    // Top Left: Settings, Sign Out, and Configure Apps
                    ToolbarItem(placement: .topBarLeading) {
                        HStack {
                            NavigationLink(destination: MachineSetupView(viewModel: viewModel)) {
                                Image(systemName: "gear")
                            }
                            
                            // --- NEW: Configure Locked Apps Button ---
                            Button {
                                isPickerPresented = true
                            } label: {
                                Image(systemName: "lock.shield")
                                    .foregroundStyle(.blue)
                            }
                            .padding(.leading, 8)
                            
                            Button(role: .destructive) {
                                viewModel.signOut() // Clears Firebase session
                                isLoggedIn = false  // Returns to LoginView
                            } label: {
                                Text("Sign Out")
                                    .foregroundStyle(.red)
                            }
                            .padding(.leading, 8)
                        }
                    }

                    // Top Right: Add Child
                    ToolbarItem(placement: .primaryAction) {
                        Button { showingAddChildSheet = true } label: {
                            Label("Add Child", systemImage: "person.badge.plus")
                        }
                    }
                }
                // --- FAMILY ACTIVITY PICKER (Moves config to Parent Side) ---
                .familyActivityPicker(isPresented: $isPickerPresented, selection: $screenTimeManager.activitySelection)
                .onChange(of: isPickerPresented) { _, isPresented in
                    if !isPresented {
                        // Save changes when the parent closes the picker
                        screenTimeManager.saveSelectionAndLock()
                    }
                }
                // Sheet to show the 6-digit Invite Code
                .sheet(item: $selectedChildForInvite) { child in
                    VStack(spacing: 20) {
                        Text("Link \(child.name)'s Device")
                            .font(.headline)
                        Text("Enter this code on the child's device:")
                            .foregroundStyle(.secondary)
                        
                        if let code = viewModel.invitationCode {
                            Text(code)
                                .font(.system(size: 50, weight: .bold, design: .monospaced))
                                .foregroundStyle(.blue)
                        } else {
                            ProgressView()
                        }
                        
                        Text("This code will link this specific profile to the child's Apple ID.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .presentationDetents([.medium])
                }
                // Sheet to Add a Child
                .sheet(isPresented: $showingAddChildSheet) {
                    NavigationStack {
                        Form {
                            TextField("Child's Name", text: $newChildName)
                        }
                        .navigationTitle("Add a Child")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    viewModel.addChild(name: newChildName)
                                    newChildName = ""
                                    showingAddChildSheet = false
                                }
                            }
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    showingAddChildSheet = false
                                    newChildName = ""
                                }
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }
            }
        }
    }
}

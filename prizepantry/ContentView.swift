import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ChildViewModel()
    
    // Binding to control the app's root login state
    @Binding var isLoggedIn: Bool
    
    @State private var showingAddChildSheet = false
    @State private var newChildName = ""
    @State private var selectedChildForInvite: Child?
    
    // State for showing the Admin Code (New Feature)
    @State private var showingUnlockCodeSheet = false

    var body: some View {
        // 1. CHECK MODE: If the user is linked as a child, show the child dashboard
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
                                                        Text("Linked").font(.caption).foregroundStyle(.green)
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                // 1. SETTINGS BUTTON (NEW)
                                                NavigationLink(destination: ChildSettingsView(viewModel: viewModel, child: child)) {
                                                    Image(systemName: "slider.horizontal.3")
                                                        .foregroundStyle(.blue)
                                                        .padding(.trailing, 8)
                                                }
                                                
                                                // 2. LINK BUTTON (Existing)
                                                Button {
                                                    viewModel.generateInviteCode(for: child)
                                                    selectedChildForInvite = child
                                                } label: {
                                                    Image(systemName: "key.fill").foregroundStyle(.orange)
                                                }
                                                .buttonStyle(.borderless)
                                                .padding(.trailing, 10)
                                                
                                                // 3. TOKEN CONTROLS (Existing)
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
                            
                            // Configure Apps Button (Generates Admin Code)
                            Button {
                                viewModel.generateSettingsUnlockCode()
                                showingUnlockCodeSheet = true
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
                // Sheet to display the Admin Code to the Parent
                .sheet(isPresented: $showingUnlockCodeSheet) {
                    VStack(spacing: 20) {
                        Image(systemName: "lock.open.iphone")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        Text("Configure Child's Device")
                            .font(.headline)
                        
                        Text("Enter this code on the child's device to access their App Lock settings:")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        if let code = viewModel.settingsUnlockCode {
                            Text(code)
                                .font(.system(size: 50, weight: .bold, design: .monospaced))
                                .foregroundStyle(.blue)
                        } else {
                            ProgressView()
                        }
                        
                        Button("Done") {
                            showingUnlockCodeSheet = false
                        }
                        .padding(.top)
                    }
                    .presentationDetents([.medium])
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

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ChildViewModel()
    @Binding var isLoggedIn: Bool
    
    @State private var showingAddChildSheet = false
    @State private var newChildName = ""
    @State private var selectedChildForInvite: Child?
    @State private var showingUnlockCodeSheet = false

    var body: some View {
        if viewModel.isChildAccount {
            ChildDashboardView(viewModel: viewModel)
        }
        else {
            NavigationStack {
                List {
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
                            
                            // 1. SETTINGS
                            NavigationLink(destination: ChildSettingsView(viewModel: viewModel, child: child)) {
                                Image(systemName: "slider.horizontal.3").foregroundStyle(.blue)
                            }
                            .buttonStyle(.borderless)
                            .padding(.trailing, 5)
                            
                            // 2. LINK (Only if not linked)
                            if child.linkedUserId == nil {
                                Button {
                                    viewModel.generateInviteCode(for: child)
                                    selectedChildForInvite = child
                                } label: {
                                    Image(systemName: "key.fill").foregroundStyle(.orange)
                                }
                                .buttonStyle(.borderless)
                            } else {
                                // ✅ 3. NEW: STOP SESSION (Take away time)
                                Button {
                                    viewModel.stopSession(for: child)
                                } label: {
                                    Image(systemName: "lock.slash.fill").foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                                .padding(.trailing, 5)
                            }

                            // 4. TOKENS
                            Button {
                                if child.tokenBalance > 0 { viewModel.updateTokens(child: child, amount: child.tokenBalance - 1) }
                            } label: { Image(systemName: "minus.circle").foregroundStyle(.red) }
                            .buttonStyle(.borderless)
                            
                            Button {
                                viewModel.updateTokens(child: child, amount: child.tokenBalance + 1)
                            } label: { Image(systemName: "plus.circle.fill").foregroundStyle(.green) }
                            .buttonStyle(.borderless)
                        }
                    }
                    .onDelete(perform: viewModel.deleteChild)
                }
                .navigationTitle("Prize Pantry")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        HStack {
                            NavigationLink(destination: MachineSetupView(viewModel: viewModel)) { Image(systemName: "gear") }
                            Button {
                                viewModel.generateSettingsUnlockCode()
                                showingUnlockCodeSheet = true
                            } label: { Image(systemName: "lock.shield").foregroundStyle(.blue) }
                            .padding(.leading, 8)
                            
                            Button(role: .destructive) {
                                viewModel.signOut()
                                isLoggedIn = false
                            } label: { Text("Sign Out").foregroundStyle(.red) }
                            .padding(.leading, 8)
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button { showingAddChildSheet = true } label: {
                            Label("Add Child", systemImage: "person.badge.plus")
                        }
                    }
                }
                // ... [Sheets remain the same] ...
                .sheet(isPresented: $showingUnlockCodeSheet) {
                    VStack(spacing: 20) {
                        Text("Configure Child's Device").font(.headline)
                        if let code = viewModel.settingsUnlockCode {
                            Text(code).font(.largeTitle).bold().foregroundStyle(.blue)
                        } else { ProgressView() }
                        Button("Done") { showingUnlockCodeSheet = false }
                    }
                    .presentationDetents([.medium])
                }
                .sheet(item: $selectedChildForInvite) { child in
                    VStack(spacing: 20) {
                        Text("Link Device").font(.headline)
                        if let code = viewModel.invitationCode {
                            Text(code).font(.largeTitle).bold().foregroundStyle(.blue)
                        } else { ProgressView() }
                        Button("Done") { selectedChildForInvite = nil }
                    }
                    .presentationDetents([.medium])
                }
                .sheet(isPresented: $showingAddChildSheet) {
                    NavigationStack {
                        Form { TextField("Child's Name", text: $newChildName) }
                        .toolbar {
                            Button("Save") {
                                viewModel.addChild(name: newChildName)
                                newChildName = ""; showingAddChildSheet = false
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }
            }
        }
    }
}

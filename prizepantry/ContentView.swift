import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ChildViewModel()
    
    @State private var showingAddChildSheet = false
    @State private var newChildName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.children) { child in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(child.name).font(.headline)
                            Text("\(child.tokenBalance) Tokens")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        
                        // Subtract Button
                        Button {
                            if child.tokenBalance > 0 {
                                viewModel.updateTokens(child: child, amount: child.tokenBalance - 1)
                            }
                        } label: {
                            Image(systemName: "minus.circle").foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                        
                        // Add Button
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
                // --- NEW CODE START ---
                // 1. The "Gear" Icon that takes you to the Setup Screen
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: MachineSetupView(viewModel: viewModel)) {
                        Image(systemName: "gear")
                    }
                }
                // --- NEW CODE END ---

                // 2. Your existing "Add Child" button
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddChildSheet = true } label: {
                        Label("Add Child", systemImage: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddChildSheet) {
                NavigationStack {
                    Form {
                        TextField("Child's Name", text: $newChildName)
                    }
                    // This adds the heading you are looking for
                    .navigationTitle("Add a Child")
                    .navigationBarTitleDisplayMode(.inline) // Makes the title smaller/centered
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

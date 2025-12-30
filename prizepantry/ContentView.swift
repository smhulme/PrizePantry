//
//  ContentView.swift
//  prizepantry
//
//  Created by Shawn Hulme on 12/29/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.name) private var children: [Child]

    // 1. State variables to manage the pop-up and input
    @State private var showingAddChildSheet = false
    @State private var newChildName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(children) { child in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(child.name)
                                .font(.headline)
                            Text("\(child.tokenBalance) Tokens")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // The Subtract Button
                        Button {
                            if child.tokenBalance > 0 {
                                child.tokenBalance -= 1 // SwiftData saves the new lower balance
                            }
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.title2)
                                .foregroundStyle(child.tokenBalance > 0 ? .red : .gray)
                        }
                        .buttonStyle(.borderless)
                        .disabled(child.tokenBalance == 0)

                        // The Add Button
                        Button {
                            child.tokenBalance += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .onDelete(perform: deleteChildren)
            }
            .navigationTitle("Prize Pantry")
            .toolbar {
                ToolbarItem {
                    Button {
                        // 2. Open the sheet instead of adding a random child
                        showingAddChildSheet = true
                    } label: {
                        Label("Add Child", systemImage: "person.badge.plus")
                    }
                }
            }
            // 3. The Pop-up Input Window
            .sheet(isPresented: $showingAddChildSheet) {
                NavigationStack {
                    Form {
                        TextField("Child's Name", text: $newChildName)
                    }
                    .navigationTitle("Add New Child")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                addChild()
                                showingAddChildSheet = false
                            }
                            .disabled(newChildName.isEmpty) // Prevent saving empty names
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingAddChildSheet = false
                                newChildName = ""
                            }
                        }
                    }
                }
                .presentationDetents([.medium]) // Makes it a half-height pop-up
            }
            .overlay {
                if children.isEmpty {
                    ContentUnavailableView("No Children", systemImage: "person.3", description: Text("Tap the + to add a child to the pantry."))
                }
            }
        }
    }

    private func addChild() {
        // 4. Create child using the text from the TextField
        let newChild = Child(name: newChildName)
        modelContext.insert(newChild)
        newChildName = "" // Reset name for next time
    }

    private func deleteChildren(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(children[index])
        }
    }
}

//
//  ContentView.swift
//  prizepantry
//
//  Created by Shawn Hulme on 12/29/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // Access the database context to save/delete data
    @Environment(\.modelContext) private var modelContext
    
    // Automatically fetch the list of children and stay in sync
    @Query(sort: \Child.name) private var children: [Child]

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
                        .buttonStyle(.borderless) // Prevents the whole row from being tapped at once
                        .disabled(child.tokenBalance == 0) // Cannot go below zero tokens

                        // The Add Button (Your existing one)
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
                        addChild()
                    } label: {
                        Label("Add Child", systemImage: "person.badge.plus")
                    }
                }
            }
            .overlay {
                if children.isEmpty {
                    ContentUnavailableView("No Children", systemImage: "person.3", description: Text("Tap the + to add a child to the pantry."))
                }
            }
        }
    }

    private func addChild() {
        let names = ["Shawn", "Seth", "Taylor", "Riley"]
        let newChild = Child(name: names.randomElement() ?? "New Child")
        modelContext.insert(newChild) // Inserts into the database
    }

    private func deleteChildren(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(children[index])
        }
    }
}

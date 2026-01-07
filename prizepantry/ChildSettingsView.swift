//
//  ChildSettingsView.swift
//  prizepantry
//
//  Created by Shawn Hulme on 1/6/26.
//


// Create file: ChildSettingsView.swift

import SwiftUI

struct ChildSettingsView: View {
    @ObservedObject var viewModel: ChildViewModel
    var child: Child
    
    // Local state for editing
    @State private var cost: Int
    @State private var duration: Int
    
    init(viewModel: ChildViewModel, child: Child) {
        self.viewModel = viewModel
        self.child = child
        // Initialize with existing values or use defaults (5 tokens / 30 mins)
        _cost = State(initialValue: child.unlockCost ?? 5)
        _duration = State(initialValue: child.unlockDuration ?? 30)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Unlock Configuration")) {
                Stepper(value: $cost, in: 1...100) {
                    HStack {
                        Text("Cost")
                        Spacer()
                        Text("\(cost) Tokens").foregroundStyle(.secondary)
                    }
                }
                
                Stepper(value: $duration, in: 5...480, step: 5) {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(duration) Minutes").foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                Text("When \(child.name) spends \(cost) tokens, apps will unlock for \(duration) minutes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("\(child.name) Settings")
        .toolbar {
            Button("Save") {
                viewModel.updateChildSettings(child: child, cost: cost, duration: duration)
            }
        }
    }
}

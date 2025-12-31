//
//  MachineSetupView.swift
//  prizepantry
//
//  Created by Shawn Hulme on 12/31/25.
//


import SwiftUI

struct MachineSetupView: View {
    @StateObject var bluetoothManager = BluetoothManager()
    @ObservedObject var viewModel: ChildViewModel // Pass your existing ViewModel
    
    @State private var wifiSSID = ""
    @State private var wifiPass = ""
    @State private var selectedChild: Child?

    var body: some View {
        Form {
            Section("1. Connection Status") {
                if bluetoothManager.isConnected {
                    Label("Connected to Machine", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                } else {
                    Label("Searching for Machine...", systemImage: "antenna.radiowaves.left.and.right").foregroundStyle(.orange)
                }
            }
            
            Section("2. Configure Wi-Fi") {
                TextField("Wi-Fi Name (SSID)", text: $wifiSSID)
                SecureField("Wi-Fi Password", text: $wifiPass)
                Button("Send to Machine") {
                    bluetoothManager.sendWifiCredentials(ssid: wifiSSID, pass: wifiPass)
                }
                .disabled(!bluetoothManager.isConnected)
            }
            
            Section("3. Assign Card to Child") {
                Picker("Select Child", selection: $selectedChild) {
                    Text("Select a Child").tag(nil as Child?)
                    ForEach(viewModel.children) { child in
                        Text(child.name).tag(child as Child?)
                    }
                }
                
                if let _ = selectedChild {
                    Text("Scan a card on the machine now...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let scanned = bluetoothManager.scannedTag {
                        Text("Scanned Tag: \(scanned)")
                            .font(.headline)
                            .foregroundStyle(.blue)
                        
                        Button("Assign to \(selectedChild!.name)") {
                            if let child = selectedChild {
                                // Update Firestore
                                viewModel.assignTagToChild(child: child, tagID: scanned)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Machine Setup")
    }
}

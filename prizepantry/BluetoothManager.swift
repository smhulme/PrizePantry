//
//  BluetoothManager.swift
//  prizepantry
//
//  Created by Shawn Hulme on 12/31/25.
//


import Foundation
import CoreBluetooth

// UUIDs must match your ESP32 Code
let SERVICE_UUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
let CHAR_WIFI_CREDENTIALS = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8") // Write
let CHAR_SCANNED_TAG      = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a9") // Notify

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var ticketMachine: CBPeripheral?

    @Published var isConnected = false
    @Published var scannedTag: String? // Holds the tag ID when the machine scans one
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [SERVICE_UUID], options: nil)
        }
    }

    // --- 1. SEND WI-FI TO ESP32 ---
    func sendWifiCredentials(ssid: String, pass: String) {
        guard let machine = ticketMachine else { return }
        
        // Format: "SSID:PASSWORD"
        let payload = "\(ssid):\(pass)"
        if let data = payload.data(using: .utf8) {
            // Find the characteristic and write
            if let service = machine.services?.first(where: { $0.uuid == SERVICE_UUID }),
               let char = service.characteristics?.first(where: { $0.uuid == CHAR_WIFI_CREDENTIALS }) {
                machine.writeValue(data, for: char, type: .withResponse)
                print("Sent Wi-Fi Credentials: \(payload)")
            }
        }
    }

    // --- STANDARD BLE DELEGATE METHODS ---
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn { startScanning() }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        ticketMachine = peripheral
        ticketMachine?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        peripheral.discoverServices([SERVICE_UUID])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([CHAR_WIFI_CREDENTIALS, CHAR_SCANNED_TAG], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for char in characteristics {
            if char.uuid == CHAR_SCANNED_TAG {
                // Subscribe to tag scans!
                peripheral.setNotifyValue(true, for: char)
            }
        }
    }

    // --- 2. RECEIVE NEW TAG FROM ESP32 ---
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == CHAR_SCANNED_TAG, let data = characteristic.value {
            let tagString = String(data: data, encoding: .utf8)
            DispatchQueue.main.async {
                self.scannedTag = tagString // Update UI with the new tag
            }
        }
    }
}

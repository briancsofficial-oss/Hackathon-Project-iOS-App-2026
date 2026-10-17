//  Bluetooth Monitor.swift
//  Created by Brian Sanchez on 9/24/26.
//
import Foundation
import CoreBluetooth // bluetooth API

// BluetoothMonitor reports whether Bluetooth is on, off, or not allowed.
class BluetoothMonitor: NSObject, ObservableObject, CBCentralManagerDelegate {

    private var manager: CBCentralManager!

    @Published var statusText = "Checking…"

    override init() {
        super.init()
        // Creating the manager triggers iOS's Bluetooth permission prompt.
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    // Called automatically whenever Bluetooth state changes.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:    statusText = "Bluetooth On"
        case .poweredOff:   statusText = "Bluetooth Off"
        case .unauthorized: statusText = "Bluetooth Not Allowed"
        case .unsupported:  statusText = "Bluetooth Unsupported"
        default:            statusText = "Checking…"
        }
    }
}

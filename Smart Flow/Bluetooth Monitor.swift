import Foundation
import CoreBluetooth

class BluetoothMonitor: NSObject, ObservableObject, CBCentralManagerDelegate {

    private var manager: CBCentralManager!

    @Published var statusText = "Checking…"

    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
    }

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

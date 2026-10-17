import Foundation
import Network

class NetworkMonitor: ObservableObject {

    private let monitor = NWPathMonitor()

    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected = false

    @Published var isOnWiFi = false

    init() {

        monitor.pathUpdateHandler = { path in

            DispatchQueue.main.async {

                self.isConnected = path.status == .satisfied

                self.isOnWiFi = path.usesInterfaceType(.wifi)
            }
        }

        monitor.start(queue: queue)
    }
}

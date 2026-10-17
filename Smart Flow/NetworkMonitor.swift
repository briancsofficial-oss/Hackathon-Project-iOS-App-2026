//
//  NetworkMonitor.swift
//  Smart Flow
//
//  Created by Brian Sanchez on 9/24/26.

import Foundation
import Network

// NetworkMonitor checks whether the device
// currently has an available internet/network connection.
class NetworkMonitor: ObservableObject {

    // NWPathMonitor observes changes in the device's
    // network connection status.
    private let monitor = NWPathMonitor()

    // Creates a background queue where the network
    // monitoring process will run.
    private let queue = DispatchQueue(label: "NetworkMonitor")

    // Stores the current internet connection status.
    // @Published allows SwiftUI views to automatically
    // update whenever this value changes.
    @Published var isConnected = false

    // true when the connection is going through Wi-Fi.
    @Published var isOnWiFi = false

    // true when the connection is going through cellular data.
    @Published var isOnCellular = false

    // Initializes the NetworkMonitor.
    init() {

        // This closure is automatically called whenever
        // the network connection status changes.
        monitor.pathUpdateHandler = { path in

            // Update the SwiftUI-related property
            // on the main thread.
            DispatchQueue.main.async {

                // .satisfied means that a network path
                // is currently available.
                // If connected, isConnected becomes true.
                // Otherwise, it becomes false.
                self.isConnected = path.status == .satisfied

                // usesInterfaceType tells us WHICH connection is being used.
                self.isOnWiFi = path.usesInterfaceType(.wifi)
                self.isOnCellular = path.usesInterfaceType(.cellular)
            }
        }

        // Start monitoring the network connection
        // using the background queue.
        monitor.start(queue: queue)
    }
}



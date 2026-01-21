// BonjourService.swift
// VibeStatus
//
// Advertises a Bonjour service on the local network to allow iOS app
// to detect when the iPhone is physically near the Mac.
// Used for silencing notifications when user is at their desk.

import Foundation

/// Manages Bonjour service advertisement for local network discovery
@MainActor
final class BonjourService {
    static let shared = BonjourService()

    // MARK: - Properties

    private var netService: NetService?

    /// Service type for Bonjour discovery
    private let serviceType = "_vibestatus._tcp."

    /// Service name (using device name for identification)
    private var serviceName: String {
        Host.current().localizedName ?? "VibeStatus-Mac"
    }

    /// Whether the service is currently advertising
    private(set) var isAdvertising = false

    /// Custom log prefix for easy filtering
    private let logPrefix = "[🔇 BONJOUR-MAC]"

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Start advertising the Bonjour service
    func startAdvertising() {
        guard !isAdvertising else {
            print("\(logPrefix) Already advertising")
            return
        }

        print("\(logPrefix) ═══ Starting Bonjour service ═══")
        print("\(logPrefix) Service name: '\(serviceName)'")
        print("\(logPrefix) Service type: \(serviceType)")

        // Create NetService with a dummy port (0 = system assigns)
        // We don't actually open a port, just advertise presence
        netService = NetService(domain: "", type: serviceType, name: serviceName, port: 0)

        guard let service = netService else {
            print("\(logPrefix) ❌ Failed to create NetService")
            return
        }

        // Publish the service
        service.publish()
        isAdvertising = true

        print("\(logPrefix) ✅ Bonjour service started - iOS devices can now detect this Mac")
        print("\(logPrefix) iOS devices on same network will see: '\(serviceName)'")
    }

    /// Stop advertising the Bonjour service
    func stopAdvertising() {
        guard isAdvertising else {
            print("\(logPrefix) Not advertising")
            return
        }

        netService?.stop()
        netService = nil
        isAdvertising = false

        print("\(logPrefix) ⏹️ Bonjour service stopped")
    }
}

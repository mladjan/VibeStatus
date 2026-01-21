// BonjourService.swift
// VibeStatus
//
// Advertises a Bonjour service on the local network to allow iOS app
// to detect when the iPhone is physically near the Mac.
// Used for silencing notifications when user is at their desk.

import Foundation

/// Manages Bonjour service advertisement for local network discovery
@MainActor
final class BonjourService: NSObject, NetServiceDelegate {
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

    private override init() {
        super.init()
    }

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

        // Create NetService with a fixed port for proximity detection
        // We don't actually listen on this port, just advertise presence
        // Using port 9876 as a fixed identifier for VibeStatus
        netService = NetService(domain: "", type: serviceType, name: serviceName, port: 9876)

        guard let service = netService else {
            print("\(logPrefix) ❌ Failed to create NetService")
            return
        }

        // Set delegate to monitor publication status
        service.delegate = self

        // Publish the service
        print("\(logPrefix) Publishing service...")
        service.publish()
        isAdvertising = true
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

    // MARK: - NetServiceDelegate

    nonisolated func netServiceDidPublish(_ sender: NetService) {
        Task { @MainActor in
            print("\(logPrefix) ✅ Service published successfully")
            print("\(logPrefix) iOS devices can now discover: '\(sender.name)'")
        }
    }

    nonisolated func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        Task { @MainActor in
            print("\(logPrefix) ❌ Failed to publish service")
            print("\(logPrefix) Error: \(errorDict)")

            // Check specific error codes
            if let errorCode = errorDict[NetService.errorCode] {
                switch errorCode.intValue {
                case NetService.ErrorCode.collisionError.rawValue:
                    print("\(logPrefix) Error: Name collision - another service with same name exists")
                case NetService.ErrorCode.notFoundError.rawValue:
                    print("\(logPrefix) Error: Service not found")
                case NetService.ErrorCode.activityInProgress.rawValue:
                    print("\(logPrefix) Error: Activity in progress")
                default:
                    print("\(logPrefix) Error code: \(errorCode)")
                }
            }

            isAdvertising = false
        }
    }

    nonisolated func netServiceDidStop(_ sender: NetService) {
        Task { @MainActor in
            print("\(logPrefix) Service stopped")
        }
    }
}

// ProximityDetector.swift
// VibeStatusMobile
//
// Detects if iPhone is on the same local network as the Mac
// by discovering the Mac's Bonjour service.
// Used to silence notifications when user is at their desk.

import Foundation
import Network
import Combine

/// Manages Bonjour service discovery to detect Mac proximity
@MainActor
final class ProximityDetector: ObservableObject {
    static let shared = ProximityDetector()

    // MARK: - Properties

    /// Whether the Mac is currently detected on local network
    @Published private(set) var isMacNearby: Bool = false

    /// Browser for discovering Bonjour services
    private var browser: NWBrowser?

    /// Service type to discover (must match Mac's service type)
    private let serviceType = "_vibestatus._tcp"

    /// Whether discovery is currently active
    private(set) var isDiscovering = false

    /// How long to wait for discovery results before assuming Mac is away
    private let discoveryTimeout: TimeInterval = 3.0

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Start discovering Mac on local network
    func startDiscovery() {
        guard !isDiscovering else {
            print("[ProximityDetector] Already discovering")
            return
        }

        print("[ProximityDetector] 🔍 Starting discovery for \(serviceType)")

        // Create browser for Bonjour service
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: .bonjour(type: serviceType, domain: nil), using: parameters)

        guard let browser = browser else {
            print("[ProximityDetector] ❌ Failed to create browser")
            return
        }

        // Handle state changes
        browser.stateUpdateHandler = { [weak self] newState in
            Task { @MainActor [weak self] in
                self?.handleBrowserStateChange(newState)
            }
        }

        // Handle discovered services
        browser.browseResultsChangedHandler = { [weak self] results, changes in
            Task { @MainActor [weak self] in
                self?.handleBrowseResults(results)
            }
        }

        // Start browsing
        browser.start(queue: .main)
        isDiscovering = true
    }

    /// Stop discovering Mac
    func stopDiscovery() {
        guard isDiscovering else {
            print("[ProximityDetector] Not discovering")
            return
        }

        print("[ProximityDetector] ⏹️ Stopping discovery")

        browser?.cancel()
        browser = nil
        isDiscovering = false
        isMacNearby = false
    }

    /// Perform a one-time check if Mac is nearby
    /// Returns true if Mac is detected within timeout period
    func checkMacProximity() async -> Bool {
        return await withCheckedContinuation { continuation in
            // Start discovery
            startDiscovery()

            // Wait for discovery timeout
            Task {
                try? await Task.sleep(nanoseconds: UInt64(discoveryTimeout * 1_000_000_000))

                let result = self.isMacNearby
                print("[ProximityDetector] One-time check result: \(result ? "Mac nearby" : "Mac away")")

                // Stop discovery after check
                self.stopDiscovery()

                continuation.resume(returning: result)
            }
        }
    }

    // MARK: - Private Methods

    private func handleBrowserStateChange(_ newState: NWBrowser.State) {
        switch newState {
        case .ready:
            print("[ProximityDetector] ✅ Browser ready")
        case .failed(let error):
            print("[ProximityDetector] ❌ Browser failed: \(error)")
            isMacNearby = false
        case .cancelled:
            print("[ProximityDetector] Browser cancelled")
            isMacNearby = false
        default:
            break
        }
    }

    private func handleBrowseResults(_ results: Set<NWBrowser.Result>) {
        let wasNearby = isMacNearby
        isMacNearby = !results.isEmpty

        if isMacNearby != wasNearby {
            if isMacNearby {
                print("[ProximityDetector] ✅ Mac detected on local network")
                if let firstResult = results.first {
                    print("[ProximityDetector] Service: \(firstResult.endpoint)")
                }
            } else {
                print("[ProximityDetector] ⚠️ Mac no longer detected")
            }
        }

        print("[ProximityDetector] Active services: \(results.count)")
    }
}

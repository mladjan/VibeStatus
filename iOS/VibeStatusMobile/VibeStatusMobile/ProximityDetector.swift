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

    /// Last time Mac was detected
    @Published private(set) var lastDetectionDate: Date?

    /// Number of services discovered in last check
    @Published private(set) var servicesFound: Int = 0

    /// Browser for discovering Bonjour services
    private var browser: NWBrowser?

    /// Service type to discover (must match Mac's service type)
    /// Note: NWBrowser expects no trailing dot, even though NetService uses one
    private let serviceType = "_vibestatus._tcp"

    /// Whether discovery is currently active
    private(set) var isDiscovering = false

    /// How long to wait for discovery results before assuming Mac is away
    private let discoveryTimeout: TimeInterval = 3.0

    /// Custom log prefix for easy filtering
    private let logPrefix = "[🔇 PROXIMITY]"

    /// Timer for periodic proximity checks
    private var periodicCheckTimer: Timer?

    // MARK: - Initialization

    private init() {
        startPeriodicChecks()
    }

    // MARK: - Public API

    /// Start discovering Mac on local network
    func startDiscovery() {
        guard !isDiscovering else {
            print("\(logPrefix) Already discovering")
            return
        }

        print("\(logPrefix) 🔍 Starting discovery for \(serviceType)")
        print("\(logPrefix) Discovery timeout: \(discoveryTimeout)s")

        // Create browser for Bonjour service
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: .bonjour(type: serviceType, domain: nil), using: parameters)

        guard let browser = browser else {
            print("\(logPrefix) ❌ Failed to create browser")
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
            print("\(logPrefix) Not discovering")
            return
        }

        print("\(logPrefix) ⏹️ Stopping discovery")
        print("\(logPrefix) Final state - Mac nearby: \(isMacNearby), Services found: \(servicesFound)")

        browser?.cancel()
        browser = nil
        isDiscovering = false
    }

    /// Perform a one-time check if Mac is nearby
    /// Returns true if Mac is detected within timeout period
    func checkMacProximity() async -> Bool {
        print("\(logPrefix) ═══ Starting proximity check ═══")

        return await withCheckedContinuation { continuation in
            // Start discovery
            startDiscovery()

            // Wait for discovery timeout
            Task {
                try? await Task.sleep(nanoseconds: UInt64(discoveryTimeout * 1_000_000_000))

                let result = self.isMacNearby
                print("\(logPrefix) ═══ Check complete ═══")
                print("\(logPrefix) Result: \(result ? "✅ Mac nearby" : "❌ Mac away")")
                print("\(logPrefix) Services found: \(self.servicesFound)")

                if result {
                    self.lastDetectionDate = Date()
                }

                // Stop discovery after check
                self.stopDiscovery()

                continuation.resume(returning: result)
            }
        }
    }

    /// Start periodic proximity checks (every 5 minutes)
    func startPeriodicChecks() {
        print("\(logPrefix) Starting periodic proximity checks")

        // Do initial check
        Task {
            _ = await checkMacProximity()
        }

        // Schedule periodic checks every 5 minutes
        periodicCheckTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                _ = await self?.checkMacProximity()
            }
        }
    }

    /// Stop periodic proximity checks
    func stopPeriodicChecks() {
        print("\(logPrefix) Stopping periodic proximity checks")
        periodicCheckTimer?.invalidate()
        periodicCheckTimer = nil
    }

    // MARK: - Private Methods

    private func handleBrowserStateChange(_ newState: NWBrowser.State) {
        switch newState {
        case .ready:
            print("\(logPrefix) ✅ Browser ready - scanning for services...")
        case .failed(let error):
            print("\(logPrefix) ❌ Browser failed: \(error)")
            print("\(logPrefix) Check: Local Network permission granted?")
            print("\(logPrefix) Check: Mac app running with Bonjour service?")
            isMacNearby = false
            servicesFound = 0
        case .cancelled:
            print("\(logPrefix) Browser cancelled")
            // Don't reset isMacNearby - keep last known state
        case .waiting(let error):
            print("\(logPrefix) ⏳ Browser waiting: \(error)")
        default:
            break
        }
    }

    private func handleBrowseResults(_ results: Set<NWBrowser.Result>) {
        let wasNearby = isMacNearby
        let previousCount = servicesFound

        isMacNearby = !results.isEmpty
        servicesFound = results.count

        if servicesFound != previousCount {
            print("\(logPrefix) 📡 Services found: \(servicesFound)")
        }

        if isMacNearby != wasNearby {
            if isMacNearby {
                print("\(logPrefix) ✅ Mac detected on local network!")
                for (index, result) in results.enumerated() {
                    print("\(logPrefix) Service \(index + 1): \(result.endpoint)")
                }
            } else {
                print("\(logPrefix) ⚠️ Mac no longer detected")
            }
        }
    }
}

// CloudKitViewModel.swift
// VibeStatusMobile
//
// View model for CloudKit sync on iOS

import Foundation
import SwiftUI
import Combine
import VibeStatusShared

/// View model managing CloudKit sessions and sync for iOS
@MainActor
class CloudKitViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var sessions: [SessionInfo] = []
    @Published var isLoading = false
    @Published var iCloudAvailable = false
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?

    // MARK: - Initialization

    init() {
        observeCloudKitManager()

        // Start periodic refresh (every 5 seconds)
        startPeriodicRefresh()
    }

    deinit {
        refreshTimer?.invalidate()
    }

    // MARK: - CloudKit Observation

    private func observeCloudKitManager() {
        CloudKitManager.shared.$iCloudAvailable
            .receive(on: DispatchQueue.main)
            .assign(to: &$iCloudAvailable)

        CloudKitManager.shared.$lastSyncDate
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastSyncDate)

        CloudKitManager.shared.$syncError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error?.localizedDescription
            }
            .store(in: &cancellables)
    }

    // MARK: - Refresh Operations

    /// Fetches sessions from CloudKit
    func refreshSessions() async {
        isLoading = true
        errorMessage = nil

        await CloudKitManager.shared.checkiCloudStatus()

        guard CloudKitManager.shared.iCloudAvailable else {
            await MainActor.run {
                errorMessage = "iCloud not available. Please sign in to iCloud in Settings."
                isLoading = false
                sessions = []
            }
            return
        }

        let records = await CloudKitManager.shared.fetchSessions()

        await MainActor.run {
            sessions = records
                .map { VibeStatusShared.SessionInfo(from: $0) }
                .sorted { $0.timestamp > $1.timestamp }
            isLoading = false
            lastSyncDate = Date()
        }
    }

    /// Starts periodic refresh timer
    private func startPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshSessions()
            }
        }
    }

    // MARK: - Grouped Sessions

    /// Returns sessions grouped by Mac device name
    var sessionsByDevice: [String: [VibeStatusShared.SessionInfo]] {
        Dictionary(grouping: sessions) { _ in "Mac" }
    }
}

// MARK: - SessionInfo Extension for iOS

extension VibeStatusShared.SessionInfo {
    var statusColor: Color {
        switch status {
        case .working: return .orange
        case .idle: return .green
        case .needsInput: return .blue
        case .notRunning: return .gray
        }
    }

    var statusEmoji: String {
        status.emoji
    }
}

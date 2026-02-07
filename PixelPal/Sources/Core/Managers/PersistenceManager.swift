import Foundation
import Combine

/// Manages persistence of app data using Codable JSON files.
/// Stores data in Application Support directory for durability.
@MainActor
class PersistenceManager: ObservableObject {
    /// Shared instance for app-wide access.
    static let shared = PersistenceManager()

    /// Published user profile (nil if not onboarded).
    @Published var userProfile: UserProfile?

    /// Published progress state.
    @Published var progressState: ProgressState

    /// Published entitlements.
    @Published var entitlements: Entitlements

    /// File names for persistence.
    private enum FileName {
        static let userProfile = "UserProfile.json"
        static let progressState = "ProgressState.json"
        static let entitlements = "Entitlements.json"
        static let dailyHistory = "DailyHistory.json"
        static let phaseDecayState = "PhaseDecayState.json"
    }

    /// Application Support directory for this app.
    private var appSupportURL: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = urls[0].appendingPathComponent("PixelPal", isDirectory: true)

        // Create directory if needed
        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        return appSupport
    }

    private init() {
        // Load existing data or create defaults
        self.userProfile = Self.load(FileName.userProfile, as: UserProfile.self)
        self.progressState = Self.load(FileName.progressState, as: ProgressState.self) ?? ProgressState.createNew()
        self.entitlements = Self.load(FileName.entitlements, as: Entitlements.self) ?? Entitlements.createFree()

        // Migrate from legacy SharedData if needed
        migrateFromLegacyIfNeeded()
    }

    // MARK: - Public API

    /// Saves the user profile after onboarding.
    func saveUserProfile(_ profile: UserProfile) {
        self.userProfile = profile
        save(profile, to: FileName.userProfile)
    }

    /// Updates and saves progress state.
    func updateProgress(_ update: (inout ProgressState) -> Void) {
        update(&progressState)
        save(progressState, to: FileName.progressState)
    }

    /// Updates and saves entitlements.
    func updateEntitlements(_ update: (inout Entitlements) -> Void) {
        update(&entitlements)
        save(entitlements, to: FileName.entitlements)
    }

    /// Saves all current state to disk.
    func saveAll() {
        if let profile = userProfile {
            save(profile, to: FileName.userProfile)
        }
        save(progressState, to: FileName.progressState)
        save(entitlements, to: FileName.entitlements)
    }

    /// Clears all persisted data (for testing/reset).
    func clearAll() {
        userProfile = nil
        progressState = ProgressState.createNew()
        entitlements = Entitlements.createFree()

        delete(FileName.userProfile)
        delete(FileName.progressState)
        delete(FileName.entitlements)

        // Also clear legacy data
        SharedData.clearAll()
    }

    /// Whether onboarding has been completed.
    var hasCompletedOnboarding: Bool {
        userProfile?.hasCompletedOnboarding ?? false
    }

    // MARK: - Daily History

    /// Loads daily history from disk.
    var dailyHistory: DailyHistory? {
        Self.load(FileName.dailyHistory, as: DailyHistory.self)
    }

    /// Saves daily history to disk.
    func saveDailyHistory(_ history: DailyHistory) {
        save(history, to: FileName.dailyHistory)
    }

    // MARK: - Phase Decay State

    /// Loads phase decay state from disk.
    var phaseDecayState: PhaseDecayState? {
        Self.load(FileName.phaseDecayState, as: PhaseDecayState.self)
    }

    /// Saves phase decay state to disk.
    func savePhaseDecayState(_ state: PhaseDecayState) {
        save(state, to: FileName.phaseDecayState)
    }

    // MARK: - Private Helpers

    private func save<T: Encodable>(_ object: T, to fileName: String) {
        let url = appSupportURL.appendingPathComponent(fileName)
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: url, options: .atomic)
        } catch {
            print("PersistenceManager: Failed to save \(fileName): \(error)")
        }
    }

    private static func load<T: Decodable>(_ fileName: String, as type: T.Type) -> T? {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let url = urls[0]
            .appendingPathComponent("PixelPal", isDirectory: true)
            .appendingPathComponent(fileName)

        guard let data = try? Data(contentsOf: url) else { return nil }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("PersistenceManager: Failed to load \(fileName): \(error)")
            return nil
        }
    }

    private func delete(_ fileName: String) {
        let url = appSupportURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Legacy Migration

    /// Migrates data from legacy SharedData (UserDefaults) to new persistence.
    private func migrateFromLegacyIfNeeded() {
        // Check if we have legacy data but no new profile
        guard userProfile == nil else { return }

        // Only migrate if legacy gender exists
        guard let legacyGender = SharedData.loadGender() else { return }

        // If legacy gender exists, create profile from it
        // We assume the upgrade date as baseline (cumulative starts from 0)
        let profile = UserProfile(
            selectedGender: legacyGender,
            selectedStarterStyle: "default",
            createdAt: Date(),
            hasCompletedOnboarding: true
        )

        saveUserProfile(profile)

        // Initialize progress with today's steps as starting point
        let todaySteps = SharedData.loadSteps()
        updateProgress { state in
            state.todaySteps = todaySteps
            // Cumulative starts at 0 for migrated users
            state.totalStepsSinceStart = 0
        }

        print("PersistenceManager: Migrated from legacy SharedData")
    }
}

// MARK: - SharedData Extension for Migration

extension SharedData {
    /// Clears all legacy UserDefaults data.
    static func clearAll() {
        guard let defaults = UserDefaults(suiteName: Keys.suiteName) else { return }
        defaults.removeObject(forKey: Keys.avatarState)
        defaults.removeObject(forKey: Keys.lastUpdateDate)
        defaults.removeObject(forKey: Keys.currentSteps)
        defaults.removeObject(forKey: Keys.gender)
    }
}

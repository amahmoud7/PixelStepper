import SwiftUI
import StoreKit
import ActivityKit

/// Profile tab: native grouped list over the app gradient.
/// Character header, Lock Screen (Live Activity), Premium, Health help, Share, About.
struct ProfileView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var healthManager: HealthKitManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var showManageSubscriptions = false
    @State private var showStepsHelp = false
    @State private var isRestoring = false
    @State private var showRestoreAlert = false
    @State private var restoreAlertTitle = ""
    @State private var restoreAlertMessage = ""
    /// Live Activities can be switched off per app in Settings; re-checked whenever the app becomes active.
    @State private var activitiesEnabled = true

    private var isPremium: Bool { appState.storeManager.isPremium }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        List {
            headerSection
            lockScreenSection
            premiumSection
            healthSection
            shareSection
            aboutSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .tint(Theme.purpleText)
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .alert("Enable Step Tracking", isPresented: $showStepsHelp) {
            Button("Open Health App") {
                if let url = URL(string: "x-apple-health://") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Dismiss", role: .cancel) { }
        } message: {
            Text("To enable step tracking:\n\n1. Open the Health app\n2. Tap your profile icon (top right)\n3. Tap \"Apps\" under Privacy\n4. Tap \"Pixel Stepper\"\n5. Turn on \"Steps\"")
        }
        .alert(restoreAlertTitle, isPresented: $showRestoreAlert) {
            Button("OK") { }
        } message: {
            Text(restoreAlertMessage)
        }
        .onAppear { refreshActivitiesEnabled() }
        .onChange(of: scenePhase) { phase in
            if phase == .active { refreshActivitiesEnabled() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            HStack(spacing: Space.l) {
                AvatarView(
                    state: appState.avatarState,
                    gender: appState.gender,
                    phase: appState.currentPhase,
                    size: 52,
                    loadout: appState.currentLoadout
                )
                .frame(width: 64, height: 64)
                .background(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(Theme.phaseColor(appState.currentPhase).opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                                .stroke(Theme.phaseColor(appState.currentPhase).opacity(0.35), lineWidth: 1.5)
                        )
                )
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("Phase \(appState.currentPhase) · \(Theme.phaseName(appState.currentPhase))")
                        .font(.ppSection)
                        .foregroundColor(Theme.textPrimary)

                    Text(appState.avatarState.description)
                        .font(.ppCaption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.vertical, Space.xs)
            .accessibilityElement(children: .combine)
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Lock Screen

    private var lockScreenSection: some View {
        Section {
            Toggle(isOn: liveActivityBinding) {
                Label("Live Activity", systemImage: "antenna.radiowaves.left.and.right")
                    .foregroundColor(Theme.textPrimary)
            }
            .tint(Theme.mint)
            .disabled(!activitiesEnabled)
        } header: {
            Text("Lock Screen")
        } footer: {
            if activitiesEnabled {
                Text("Shows your character and steps on the Lock Screen and in the Dynamic Island.")
            } else {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("Live Activities are turned off for Pixel Stepper.")
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.ppCaption.weight(.semibold))
                }
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var liveActivityBinding: Binding<Bool> {
        Binding(
            get: { appState.liveActivityManager.isActive },
            set: { isOn in
                Haptics.soft()
                if isOn {
                    appState.liveActivityManager.startActivity(
                        steps: Int(healthManager.currentSteps),
                        state: appState.avatarState,
                        gender: appState.gender,
                        phase: appState.currentPhase
                    )
                } else {
                    appState.liveActivityManager.endActivity()
                }
            }
        )
    }

    private func refreshActivitiesEnabled() {
        activitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // MARK: - Premium

    private var premiumSection: some View {
        Section("Premium") {
            HStack {
                Label {
                    Text("Status")
                        .foregroundColor(Theme.textPrimary)
                } icon: {
                    Image(systemName: isPremium ? "crown.fill" : "crown")
                        .foregroundColor(Theme.gold)
                }
                Spacer()
                Text(isPremium ? "Active" : "Free")
                    .foregroundColor(isPremium ? Theme.mint : Theme.textSecondary)
            }
            .accessibilityElement(children: .combine)

            if isPremium {
                Button {
                    Haptics.soft()
                    showManageSubscriptions = true
                } label: {
                    Text("Manage subscription")
                }
            } else {
                Button {
                    Haptics.tap()
                    appState.showPaywall = true
                } label: {
                    Text("Upgrade")
                }
            }

            Button {
                restorePurchases()
            } label: {
                HStack {
                    Text("Restore Purchases")
                    if isRestoring {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isRestoring)
        }
        .listRowBackground(Theme.surface)
    }

    private func restorePurchases() {
        Haptics.soft()
        isRestoring = true
        let store = appState.storeManager
        store.errorMessage = nil
        Task {
            await store.restorePurchases()
            isRestoring = false
            if store.isPremium {
                Haptics.success()
                restoreAlertTitle = "Premium restored"
                restoreAlertMessage = "All Premium features are unlocked."
            } else if let error = store.errorMessage {
                Haptics.error()
                restoreAlertTitle = "Couldn't restore purchases"
                restoreAlertMessage = error
            } else {
                Haptics.warning()
                restoreAlertTitle = "No purchases to restore"
                restoreAlertMessage = "We couldn't find an active Premium subscription for this Apple ID."
            }
            showRestoreAlert = true
        }
    }

    // MARK: - Health

    private var healthSection: some View {
        Section("Health") {
            Button {
                Haptics.tap()
                showStepsHelp = true
            } label: {
                Label {
                    Text("Step access help")
                        .foregroundColor(Theme.textPrimary)
                } icon: {
                    Image(systemName: "questionmark.circle")
                }
            }
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Share

    private var shareSection: some View {
        Section {
            Button {
                Haptics.tap()
                appState.showShareSheet = true
            } label: {
                Label {
                    Text("Share progress")
                        .foregroundColor(Theme.textPrimary)
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            Link("Privacy Policy", destination: URL(string: "https://github.com/amahmoud7/PixelStepper/blob/main/PRIVACY_POLICY.md")!)
            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            LabeledContent("Version", value: appVersion)
                .foregroundColor(Theme.textPrimary)
        }
        .listRowBackground(Theme.surface)
    }
}

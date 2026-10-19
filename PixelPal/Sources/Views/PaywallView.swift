import SwiftUI
import StoreKit

/// Premium paywall — accessible from any phase, aspirational messaging.
/// Plans, CTA and legal live in a pinned bottom panel so the price and button are always visible.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var storeManager: StoreManager
    @State private var selectedProduct: Product?
    @State private var isPurchasing: Bool = false
    @State private var isRestoring: Bool = false
    @State private var showError: Bool = false
    @State private var errorTitle: String = "Purchase didn't go through"
    @State private var showNothingToRestore: Bool = false
    @State private var isTrialEligible: Bool = false
    @State private var appeared = false

    let gender: Gender
    var currentPhase: Int = 1

    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.ppTitle)
                                .foregroundColor(Theme.textTertiary)
                                .minTapTarget()
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close")
                    }
                    .padding(.horizontal, Space.m)
                    .padding(.top, Space.s)

                    Spacer().frame(height: Space.xs)

                    // Evolution timeline
                    EvolutionTimeline(gender: gender, currentPhase: currentPhase)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                    Spacer().frame(height: Space.xl)

                    // Title — dynamic based on phase
                    Text(headlineText)
                        .font(.ppTitle)
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Space.xl)
                        .opacity(appeared ? 1 : 0)
                        .accessibilityAddTraits(.isHeader)

                    Spacer().frame(height: Space.s)

                    Text(subtitleText)
                        .font(.ppBody)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 28)

                    // Benefits
                    VStack(spacing: 0) {
                        BenefitRow(icon: "sparkles", color: Theme.amber,
                                   title: "Reach Phase 3 & 4",
                                   desc: "Unlock the Thriving and Legendary auras")
                        BenefitRow(icon: "target", color: Theme.mint,
                                   title: "5 daily missions and a weekly challenge",
                                   desc: "More goals to walk toward")
                        BenefitRow(icon: "snowflake", color: Theme.cyan,
                                   title: "Streak freeze",
                                   desc: "Protect your streak once per week")
                        BenefitRow(icon: "paintpalette.fill", color: Theme.purpleText,
                                   title: "Premium share backgrounds",
                                   desc: "Sunset, Ocean and Retro card styles")
                    }
                    .padding(.horizontal, Space.screen)

                    Spacer().frame(height: Space.xl)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // App Store screenshots must not show prices, so demo captures omit the plans panel.
                if !LaunchFlags.demoData {
                    purchasePanel
                }
            }
        }
        .alert(errorTitle, isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(storeManager.errorMessage ?? "Something went wrong. Please try again.")
        }
        .onAppear {
            if selectedProduct == nil {
                selectedProduct = storeManager.yearlyProduct
            }
            withMotion(Motion.smooth, reduceMotion: reduceMotion) {
                appeared = true
            }
        }
        .onChange(of: storeManager.products) { _ in
            // Products loaded async — auto-select yearly once available
            if selectedProduct == nil {
                selectedProduct = storeManager.yearlyProduct
            }
        }
        .task {
            // Ensure products are loaded when paywall opens
            if storeManager.products.isEmpty {
                await storeManager.loadProducts()
            }
            if let yearly = storeManager.yearlyProduct {
                isTrialEligible = await storeManager.isTrialEligible(for: yearly)
            }
        }
    }

    // MARK: - Pinned Purchase Panel

    private var purchasePanel: some View {
        VStack(spacing: Space.s) {
            // Subscription options
            if storeManager.isLoading {
                HStack(spacing: Space.s) {
                    ProgressView()
                        .tint(.white)
                    Text("Loading plans…")
                        .font(.ppRowTitle)
                        .foregroundColor(Theme.textTertiary)
                }
                .frame(minHeight: 44)
            } else if storeManager.products.isEmpty {
                VStack(spacing: Space.xs) {
                    Text("Unable to load subscription plans")
                        .font(.ppBody.weight(.semibold))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                    Text("Please check your internet connection and try again.")
                        .font(.ppCaption)
                        .foregroundColor(Theme.textTertiary)
                        .multilineTextAlignment(.center)
                    Button(action: {
                        Haptics.soft()
                        Task { await storeManager.loadProducts() }
                    }) {
                        Text("Retry")
                            .font(.ppBody.weight(.bold))
                            .foregroundColor(Theme.purpleText)
                            .padding(.horizontal, Space.xl)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .stroke(Theme.purple.opacity(0.5), lineWidth: 1.5)
                            )
                            .minTapTarget()
                    }
                    .buttonStyle(PPPressableStyle())
                }
            } else {
                VStack(spacing: Space.s) {
                    if let yearly = storeManager.yearlyProduct {
                        PlanCard(
                            product: yearly,
                            isSelected: selectedProduct?.id == yearly.id,
                            badge: "BEST VALUE",
                            badgeColor: Theme.mint
                        ) {
                            selectedProduct = yearly
                        }
                    }

                    if let monthly = storeManager.monthlyProduct {
                        PlanCard(
                            product: monthly,
                            isSelected: selectedProduct?.id == monthly.id,
                            badge: nil,
                            badgeColor: .clear
                        ) {
                            selectedProduct = monthly
                        }
                    }
                }

                // Purchase CTA
                Button {
                    Haptics.prepare()
                    Haptics.tap()
                    purchase()
                } label: {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(purchaseButtonTitle)
                    }
                }
                .buttonStyle(PPPrimaryButtonStyle(
                    colors: selectedProduct != nil
                        ? [Theme.purple, Theme.purpleDeep]
                        : [Theme.surfaceStrong, Theme.surface]
                ))
                .disabled(selectedProduct == nil || isPurchasing)

                // Price disclosure directly under the CTA
                if let disclosure = priceDisclosure {
                    Text(disclosure)
                        .font(.ppCaption)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if storeManager.purchaseIsPending {
                    Label("Waiting for approval. You'll get Premium as soon as it's approved.", systemImage: "hourglass")
                        .font(.ppCaption)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Restore + legal
            HStack(spacing: Space.l) {
                Button(action: restore) {
                    Text("Restore Purchases")
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isRestoring)
                .alert("No purchases to restore", isPresented: $showNothingToRestore) {
                    Button("OK") { }
                } message: {
                    Text("We couldn't find an active Premium subscription for this Apple ID.")
                }

                Link("Privacy Policy", destination: URL(string: "https://github.com/amahmoud7/PixelStepper/blob/main/PRIVACY_POLICY.md")!)
                    .frame(minHeight: 44)
                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .frame(minHeight: 44)
            }
            .font(.ppCaption)
            .foregroundColor(Theme.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, Space.screen)
        .padding(.top, Space.m)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.stroke)
                .frame(height: 1)
        }
    }

    // MARK: - Dynamic Copy

    private var headlineText: String {
        switch currentPhase {
        case 1: return "Unlock the full journey"
        case 2: return "Your character is ready to evolve"
        case 3: return "Go Legendary"
        default: return "Unlock everything"
        }
    }

    private var subtitleText: String {
        switch currentPhase {
        case 1: return "Premium unlocks all 4 phases, extra missions, and streak protection."
        case 2: return "Phase 3 & 4 are waiting. Plus extra missions and streak freeze."
        case 3: return "One more evolution to go. Plus all premium perks."
        default: return "Get the most out of Pixel Stepper."
        }
    }

    /// Trial length for the selected plan without the trailing " free" ("1 week"), when the user can claim it.
    private var selectedTrialLength: String? {
        guard isTrialEligible, let product = selectedProduct,
              let trialText = storeManager.trialDescription(for: product) else { return nil }
        return trialText.replacingOccurrences(of: " free", with: "")
    }

    private var purchaseButtonTitle: String {
        guard let trial = selectedTrialLength else { return "Unlock Premium" }
        return "Start your \(trial) free trial"
    }

    /// "1 week free, then $29.99/year. Cancel anytime in Settings."
    private var priceDisclosure: String? {
        guard let product = selectedProduct else { return nil }
        let price = "\(product.displayPrice)\(periodSuffix(for: product))"
        let renewal = "Auto-renews unless cancelled at least 24 hours before the period ends."
        if let trial = selectedTrialLength {
            return "\(trial) free, then \(price). Cancel anytime in Settings. \(renewal)"
        }
        return "\(price). Cancel anytime in Settings. \(renewal)"
    }

    /// "/year", "/month", "/3 months"; empty for non-subscription products.
    private func periodSuffix(for product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else { return "" }
        let unit: String
        switch period.unit {
        case .day: unit = "day"
        case .week: unit = "week"
        case .month: unit = "month"
        case .year: unit = "year"
        default: unit = "period"
        }
        return period.value == 1 ? "/\(unit)" : "/\(period.value) \(unit)s"
    }

    // MARK: - Actions

    private func purchase() {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        // Clear any stale error so a user cancel isn't reported as a failure.
        storeManager.errorMessage = nil

        Task {
            let success = await storeManager.purchase(product)
            isPurchasing = false

            if success {
                Haptics.success()
                PersistenceManager.shared.updateProgress { progress in
                    progress.hasSeenPaywall = true
                }
                dismiss()
            } else if storeManager.purchaseIsPending {
                // Ask to Buy etc.: the inline note explains; not an error.
                return
            } else if storeManager.errorMessage != nil {
                Haptics.error()
                errorTitle = "Purchase didn't go through"
                showError = true
            }
        }
    }

    private func restore() {
        Haptics.soft()
        isRestoring = true
        storeManager.errorMessage = nil
        Task {
            await storeManager.restorePurchases()
            isRestoring = false
            if storeManager.isPremium {
                Haptics.success()
                dismiss()
            } else if storeManager.errorMessage != nil {
                // Restore itself failed (e.g. offline): show the real error.
                Haptics.error()
                errorTitle = "Couldn't restore purchases"
                showError = true
            } else {
                Haptics.warning()
                showNothingToRestore = true
            }
        }
    }
}

// MARK: - Evolution Timeline

private struct EvolutionTimeline: View {
    let gender: Gender
    let currentPhase: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...4, id: \.self) { phase in
                PhaseNode(
                    phase: phase,
                    gender: gender,
                    isCurrent: phase == currentPhase,
                    isUnlocked: phase <= currentPhase,
                    isPremiumLocked: phase > 2
                )

                if phase < 4 {
                    // Connector line
                    Rectangle()
                        .fill(phase < currentPhase
                            ? Theme.phaseColor(phase).opacity(0.5)
                            : Theme.stroke)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, Space.xl)
        // Nodes are fixed 52pt circles; keep their labels from overflowing.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}

/// One phase in the timeline. Phases change the aura color around the character,
/// not the sprite itself, so every node shows the user's own character in that phase's aura.
private struct PhaseNode: View {
    let phase: Int
    let gender: Gender
    let isCurrent: Bool
    let isUnlocked: Bool
    let isPremiumLocked: Bool

    @State private var pulsing = false

    private var phaseColor: Color {
        Theme.phaseColor(phase)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Glow ring for current phase
                if isCurrent {
                    Circle()
                        .stroke(phaseColor.opacity(0.4), lineWidth: 2)
                        .frame(width: 58, height: 58)
                        .scaleEffect(pulsing ? 1.1 : 1.0)
                        .ambientLoop($pulsing, animation: Motion.ambient(1.5))
                }

                // Aura
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [phaseColor.opacity(isUnlocked ? 0.45 : 0.15), phaseColor.opacity(0.05)],
                            center: .center,
                            startRadius: 4,
                            endRadius: 26
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(decorative: SpriteAssets.spriteName(gender: gender, state: .vital, frame: 1))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .shadow(color: phaseColor.opacity(isUnlocked ? 0.9 : 0.3), radius: 4)
                    .opacity(isUnlocked ? 1.0 : 0.45)

                // Premium badge for locked phases
                if !isUnlocked && isPremiumLocked {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "crown.fill")
                                .font(.ppMicro)
                                .imageScale(.small)
                                .foregroundColor(Theme.gold)
                                .padding(3)
                                .background(
                                    Circle()
                                        .fill(Color(red: 0.15, green: 0.1, blue: 0.25))
                                )
                        }
                    }
                    .frame(width: 52, height: 52)
                }
            }

            Text(Theme.phaseName(phase))
                .font(Font.ppMicro.weight(isCurrent ? .bold : .medium))
                .foregroundColor(isCurrent ? Theme.textPrimary : Theme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var text = "Phase \(phase), \(Theme.phaseName(phase)) aura"
        if isCurrent { text += ", current" }
        if !isUnlocked && isPremiumLocked { text += ", Premium" }
        return text
    }
}

// MARK: - Benefit Row

private struct BenefitRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String

    @ScaledMetric(relativeTo: .subheadline) private var iconBox: CGFloat = 32

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.ppBody)
                .foregroundColor(color)
                .frame(width: iconBox, height: iconBox)
                .background(
                    RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                        .fill(color.opacity(0.12))
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Space.xxs) {
                Text(title)
                    .font(.ppBody.weight(.semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(desc)
                    .font(.ppMicro)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let badgeColor: Color
    let action: () -> Void

    private var perMonthText: String? {
        guard let subscription = product.subscription,
              subscription.subscriptionPeriod.unit == .year else { return nil }
        // Storefront currency, not the device locale.
        return (product.price / 12).formatted(product.priceFormatStyle)
    }

    private var priceWithPeriod: String {
        guard let sub = product.subscription else { return product.displayPrice }
        switch sub.subscriptionPeriod.unit {
        case .month: return "\(product.displayPrice)/mo"
        case .year: return "\(product.displayPrice)/yr"
        default: return product.displayPrice
        }
    }

    var body: some View {
        Button(action: {
            Haptics.select()
            action()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: Space.xxs) {
                    HStack(spacing: Space.s) {
                        Text(product.displayName)
                            .font(.ppBody.weight(.bold))
                            .foregroundColor(Theme.textPrimary)

                        if let badge {
                            Text(badge)
                                .font(.ppOverline)
                                .tracking(0.5)
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(badgeColor)
                                )
                        }
                    }

                    if let perMonth = perMonthText {
                        Text("Just \(perMonth)/month")
                            .font(.ppMicro)
                            .foregroundColor(Theme.mint)
                    } else {
                        Text(product.description)
                            .font(.ppMicro)
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(priceWithPeriod)
                    .font(.ppButton)
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(.horizontal, Space.l)
            .padding(.vertical, Space.m)
            .background(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .fill(isSelected ? Theme.purple.opacity(0.12) : Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                            .stroke(isSelected ? Theme.purple.opacity(0.6) : Theme.stroke, lineWidth: isSelected ? 2 : 1)
                    )
            )
            .motion(Motion.snappy, value: isSelected)
            .contentShape(Rectangle())
        }
        .buttonStyle(PPPressableStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

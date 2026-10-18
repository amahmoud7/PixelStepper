import SwiftUI
import StoreKit

/// Premium paywall — accessible from any phase, aspirational messaging.
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
                                   title: "All 4 evolution phases",
                                   desc: "Unlock Thriving & Legendary forms")
                        BenefitRow(icon: "target", color: Theme.mint,
                                   title: "5 daily missions",
                                   desc: "More challenges, more coins")
                        BenefitRow(icon: "snowflake", color: Theme.cyan,
                                   title: "Streak freeze",
                                   desc: "Protect your streak once per week")
                        BenefitRow(icon: "paintpalette.fill", color: Theme.purpleText,
                                   title: "Premium share cards",
                                   desc: "Exclusive backgrounds & styles")
                        BenefitRow(icon: "2.circle.fill", color: Theme.gold,
                                   title: "2x step coins",
                                   desc: "Double coins from all rewards")
                        BenefitRow(icon: "trophy.fill", color: Theme.amber,
                                   title: "Weekly challenge",
                                   desc: "Exclusive big goal with 500+ coin reward")
                    }
                    .padding(.horizontal, Space.screen)

                    Spacer().frame(height: 28)

                    // Subscription options
                    if storeManager.isLoading {
                        VStack(spacing: Space.m) {
                            ProgressView()
                                .tint(.white)
                            Text("Loading plans…")
                                .font(.ppRowTitle)
                                .foregroundColor(Theme.textTertiary)
                        }
                        .padding(.vertical, Space.screen)
                    } else if storeManager.products.isEmpty {
                        VStack(spacing: Space.m) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.ppStat)
                                .foregroundColor(Theme.amber)
                                .accessibilityHidden(true)
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
                        .padding(.vertical, Space.screen)
                        .padding(.horizontal, 32)
                    } else {
                        VStack(spacing: 10) {
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
                        .padding(.horizontal, Space.screen)
                    }

                    Spacer().frame(height: Space.xl)

                    // Purchase CTA
                    if !storeManager.products.isEmpty {
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
                        .padding(.horizontal, 32)
                    }

                    Spacer().frame(height: Space.s)

                    // Restore
                    Button(action: restore) {
                        Text("Restore purchases")
                            .font(.ppBody)
                            .foregroundColor(Theme.textSecondary)
                            .padding(.horizontal, Space.s)
                            .minTapTarget()
                    }
                    .buttonStyle(.plain)
                    .disabled(isRestoring)
                    // Attached here (not on the root) so it never competes with the purchase error alert.
                    .alert("No purchases to restore", isPresented: $showNothingToRestore) {
                        Button("OK") { }
                    } message: {
                        Text("We couldn't find an active Premium subscription for this Apple ID.")
                    }

                    Spacer().frame(height: Space.xs)

                    // Terms
                    Text(showsTrial
                         ? "Free trial starts immediately. Cancel anytime. Auto-renews unless cancelled 24 hours before period end."
                         : "Cancel anytime. Auto-renews unless cancelled 24 hours before period end.")
                        .font(.ppCaption)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Spacer().frame(height: Space.xs)

                    // Privacy & Terms links
                    HStack(spacing: Space.l) {
                        Link("Privacy Policy", destination: URL(string: "https://github.com/amahmoud7/PixelStepper/blob/main/PRIVACY_POLICY.md")!)
                            .frame(minHeight: 44)
                        Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .frame(minHeight: 44)
                    }
                    .font(.ppCaption)
                    .foregroundColor(Theme.textSecondary)

                    Spacer().frame(height: 40)
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

    /// True only when the selected plan actually has a free trial the user can claim.
    private var showsTrial: Bool {
        isTrialEligible && selectedProduct.flatMap { storeManager.trialDescription(for: $0) } != nil
    }

    private var purchaseButtonTitle: String {
        guard isTrialEligible, let product = selectedProduct,
              let trialText = storeManager.trialDescription(for: product) else {
            return "Unlock Premium"
        }
        // trialDescription already ends in " free" ("1 week free").
        return "Start your \(trialText.replacingOccurrences(of: " free", with: "")) free trial"
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

    private var avatarState: AvatarState {
        switch phase {
        case 1: return .low
        case 2: return .neutral
        case 3, 4: return .vital
        default: return .low
        }
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

                Circle()
                    .fill(phaseColor.opacity(isUnlocked ? 0.2 : 0.06))
                    .frame(width: 52, height: 52)

                Image(decorative: SpriteAssets.spriteName(gender: gender, state: avatarState, frame: 1))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .opacity(isUnlocked ? 1.0 : 0.35)

                // Lock or premium badge for locked phases
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
        var text = "Phase \(phase), \(Theme.phaseName(phase))"
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
                VStack(alignment: .leading, spacing: Space.xs) {
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
                    }
                }

                Spacer()

                Text(priceWithPeriod)
                    .font(.ppButton)
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(Space.l)
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

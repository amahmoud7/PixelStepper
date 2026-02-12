import SwiftUI
import StoreKit

/// Premium paywall — accessible from any phase, aspirational messaging.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var storeManager: StoreManager
    @State private var selectedProduct: Product?
    @State private var isPurchasing: Bool = false
    @State private var showError: Bool = false
    @State private var isTrialEligible: Bool = false
    @State private var appeared = false

    let gender: Gender
    var currentPhase: Int = 1

    private let purple = Color(red: 0.49, green: 0.36, blue: 0.99)
    private let cyan = Color(red: 0.0, green: 0.83, blue: 1.0)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.02, blue: 0.15),
                    Color(red: 0.10, green: 0.04, blue: 0.22),
                    Color(red: 0.05, green: 0.02, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer().frame(height: 12)

                    // Evolution timeline
                    EvolutionTimeline(gender: gender, currentPhase: currentPhase)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                    Spacer().frame(height: 24)

                    // Title — dynamic based on phase
                    Text(headlineText)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 8)

                    Text(subtitleText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 28)

                    // Benefits
                    VStack(spacing: 0) {
                        BenefitRow(icon: "sparkles", color: .orange,
                                   title: "All 4 Evolution Phases",
                                   desc: "Unlock Thriving & Legendary forms")
                        BenefitRow(icon: "target", color: Color(red: 0.2, green: 0.78, blue: 0.35),
                                   title: "5 Daily Missions",
                                   desc: "More challenges, more coins")
                        BenefitRow(icon: "snowflake", color: cyan,
                                   title: "Streak Freeze",
                                   desc: "Protect your streak once per week")
                        BenefitRow(icon: "paintpalette.fill", color: purple,
                                   title: "Premium Share Cards",
                                   desc: "Exclusive backgrounds & styles")
                        BenefitRow(icon: "crown", color: Color(red: 1.0, green: 0.84, blue: 0.0),
                                   title: "Exclusive Cosmetics",
                                   desc: "Premium hats, backgrounds & accessories")
                        BenefitRow(icon: "2.circle.fill", color: Color(red: 1.0, green: 0.84, blue: 0.0),
                                   title: "2x Step Coins",
                                   desc: "Double coins from all rewards")
                        BenefitRow(icon: "trophy.fill", color: .orange,
                                   title: "Weekly Challenge",
                                   desc: "Exclusive big goal with 500+ coin reward")
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 28)

                    // Subscription options
                    if storeManager.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("Loading plans...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.vertical, 20)
                    } else if storeManager.products.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 24))
                                .foregroundColor(.yellow.opacity(0.7))
                            Text("Unable to load subscription plans")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Please check your internet connection and try again.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                            Button(action: {
                                Task { await storeManager.loadProducts() }
                            }) {
                                Text("Retry")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(purple)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .stroke(purple.opacity(0.5), lineWidth: 1.5)
                                    )
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 32)
                    } else {
                        VStack(spacing: 10) {
                            if let yearly = storeManager.yearlyProduct {
                                PlanCard(
                                    product: yearly,
                                    isSelected: selectedProduct?.id == yearly.id,
                                    badge: "BEST VALUE",
                                    badgeColor: Color(red: 0.2, green: 0.78, blue: 0.35)
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
                        .padding(.horizontal, 20)
                    }

                    Spacer().frame(height: 24)

                    // Purchase CTA
                    if !storeManager.products.isEmpty {
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            purchase()
                        }) {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(purchaseButtonTitle)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: selectedProduct != nil
                                    ? [purple, cyan.opacity(0.8)]
                                    : [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: selectedProduct != nil ? purple.opacity(0.4) : .clear, radius: 16, y: 6)
                        .disabled(selectedProduct == nil || isPurchasing)
                        .padding(.horizontal, 32)
                    }

                    Spacer().frame(height: 16)

                    // Restore
                    Button(action: restore) {
                        Text("Restore Purchases")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))
                    }

                    Spacer().frame(height: 12)

                    // Terms
                    Text(isTrialEligible
                         ? "Free trial starts immediately. Cancel anytime. Auto-renews unless cancelled 24 hours before period end."
                         : "Cancel anytime. Auto-renews unless cancelled 24 hours before period end.")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.2))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Spacer().frame(height: 40)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(storeManager.errorMessage ?? "An error occurred.")
        }
        .onAppear {
            if selectedProduct == nil {
                selectedProduct = storeManager.yearlyProduct
            }
            withAnimation(.easeOut(duration: 0.5)) {
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

    private var purchaseButtonTitle: String {
        guard isTrialEligible, let product = selectedProduct,
              let trialText = storeManager.trialDescription(for: product) else {
            return "Unlock Premium"
        }
        return "Start \(trialText) Free Trial"
    }

    // MARK: - Actions

    private func purchase() {
        guard let product = selectedProduct else { return }
        isPurchasing = true

        Task {
            let success = await storeManager.purchase(product)
            isPurchasing = false

            if success {
                PersistenceManager.shared.updateProgress { progress in
                    progress.hasSeenPaywall = true
                }
                dismiss()
            } else if storeManager.errorMessage != nil {
                showError = true
            }
        }
    }

    private func restore() {
        Task {
            await storeManager.restorePurchases()
            if storeManager.isPremium {
                dismiss()
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
                            ? phaseColor(for: phase).opacity(0.5)
                            : Color.white.opacity(0.08))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func phaseColor(for phase: Int) -> Color {
        switch phase {
        case 1: return .gray
        case 2: return Color(red: 0.0, green: 0.48, blue: 1.0)
        case 3: return Color(red: 0.49, green: 0.36, blue: 0.99)
        case 4: return Color(red: 1.0, green: 0.6, blue: 0.0)
        default: return .gray
        }
    }
}

private struct PhaseNode: View {
    let phase: Int
    let gender: Gender
    let isCurrent: Bool
    let isUnlocked: Bool
    let isPremiumLocked: Bool

    @State private var pulseScale: CGFloat = 1.0

    private var phaseColor: Color {
        switch phase {
        case 1: return .gray
        case 2: return Color(red: 0.0, green: 0.48, blue: 1.0)
        case 3: return Color(red: 0.49, green: 0.36, blue: 0.99)
        case 4: return Color(red: 1.0, green: 0.6, blue: 0.0)
        default: return .gray
        }
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
                        .scaleEffect(pulseScale)
                }

                Circle()
                    .fill(phaseColor.opacity(isUnlocked ? 0.2 : 0.06))
                    .frame(width: 52, height: 52)

                Image(SpriteAssets.spriteName(gender: gender, state: avatarState, frame: 1))
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
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
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

            Text(phaseName)
                .font(.system(size: 9, weight: isCurrent ? .bold : .medium))
                .foregroundColor(isCurrent ? .white : .white.opacity(0.35))
        }
        .onAppear {
            guard isCurrent else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }

    private var phaseName: String {
        switch phase {
        case 1: return "Seedling"
        case 2: return "Growing"
        case 3: return "Thriving"
        case 4: return "Legendary"
        default: return ""
        }
    }
}

// MARK: - Benefit Row

private struct BenefitRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let badgeColor: Color
    let action: () -> Void

    private let purple = Color(red: 0.49, green: 0.36, blue: 0.99)

    private var perMonthText: String? {
        guard let subscription = product.subscription,
              subscription.subscriptionPeriod.unit == .year else { return nil }
        let monthly = product.price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: monthly as NSDecimalNumber)
    }

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(badgeColor)
                                )
                        }
                    }

                    if let perMonth = perMonthText {
                        Text("Just \(perMonth)/month")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(red: 0.2, green: 0.78, blue: 0.35))
                    } else {
                        Text(product.description)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? purple.opacity(0.12) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? purple.opacity(0.6) : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
}

import SwiftUI
import StoreKit

/// Paywall view shown after Phase 2 unlock.
/// Follows v1.1 spec: Calm, confident, aspirational. No guilt language.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var storeManager: StoreManager
    @State private var selectedProduct: Product?
    @State private var isPurchasing: Bool = false
    @State private var showError: Bool = false

    let gender: Gender

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.12),
                    Color(red: 0.1, green: 0.04, blue: 0.18),
                    Color(red: 0.04, green: 0.1, blue: 0.12)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal)

                    // Character evolving visual
                    EvolutionPreview(gender: gender)
                        .padding(.vertical, 20)

                    // Title
                    Text("Your character is evolving")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    // Subtitle
                    Text("Unlock what this character can become.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        BenefitRow(icon: "star.fill", color: .purple,
                                   text: "Advanced evolutions (Phase 3 & 4)")
                        BenefitRow(icon: "paintpalette.fill", color: .orange,
                                   text: "Exclusive pixel skins")
                        BenefitRow(icon: "chart.line.uptrend.xyaxis", color: .blue,
                                   text: "Full progress history")
                    }
                    .padding(.vertical, 20)

                    // Subscription options
                    if storeManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        VStack(spacing: 12) {
                            if let yearly = storeManager.yearlyProduct {
                                SubscriptionOption(
                                    product: yearly,
                                    isSelected: selectedProduct?.id == yearly.id,
                                    isBestValue: true
                                ) {
                                    selectedProduct = yearly
                                }
                            }

                            if let monthly = storeManager.monthlyProduct {
                                SubscriptionOption(
                                    product: monthly,
                                    isSelected: selectedProduct?.id == monthly.id,
                                    isBestValue: false
                                ) {
                                    selectedProduct = monthly
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Purchase button
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        purchase()
                    }) {
                        if isPurchasing {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Unlock Premium")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: selectedProduct != nil
                                ? [.white, Color(white: 0.92)]
                                : [Color.white.opacity(0.5), Color.white.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: .white.opacity(selectedProduct != nil ? 0.15 : 0), radius: 8, y: 2)
                    .disabled(selectedProduct == nil || isPurchasing)
                    .padding(.horizontal, 40)

                    // Restore purchases
                    Button(action: restore) {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    // Terms
                    Text("Cancel anytime. Subscriptions auto-renew unless cancelled 24 hours before the end of the period.")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.7))
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
            // Pre-select yearly as best value
            if selectedProduct == nil {
                selectedProduct = storeManager.yearlyProduct
            }
        }
    }

    private func purchase() {
        guard let product = selectedProduct else { return }
        isPurchasing = true

        Task {
            let success = await storeManager.purchase(product)
            isPurchasing = false

            if success {
                // Mark paywall as seen
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

// MARK: - Evolution Preview

private struct EvolutionPreview: View {
    let gender: Gender

    var body: some View {
        HStack(spacing: 8) {
            // Phase 1 -> 2 (done)
            PhaseIcon(phase: 1, isUnlocked: true, gender: gender)
            Arrow(isUnlocked: true)
            PhaseIcon(phase: 2, isUnlocked: true, gender: gender)
            Arrow(isUnlocked: false)
            // Phase 3 -> 4 (locked)
            PhaseIcon(phase: 3, isUnlocked: false, gender: gender)
            Arrow(isUnlocked: false)
            PhaseIcon(phase: 4, isUnlocked: false, gender: gender)
        }
    }
}

private struct PhaseIcon: View {
    let phase: Int
    let isUnlocked: Bool
    let gender: Gender
    @State private var pulseScale: CGFloat = 1.0

    private var stateForPhase: AvatarState {
        switch phase {
        case 1: return .low
        case 2: return .neutral
        case 3, 4: return .vital
        default: return .low
        }
    }

    private var phaseColor: Color {
        switch phase {
        case 1: return .gray
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(phaseColor.opacity(isUnlocked ? 0.2 : 0.05))
                .frame(width: 60, height: 60)

            if isUnlocked {
                Image(SpriteAssets.spriteName(gender: gender, state: stateForPhase, frame: 1))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
            } else {
                Image(SpriteAssets.spriteName(gender: gender, state: stateForPhase, frame: 1))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .opacity(0.4)
                    .overlay(
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white.opacity(0.9))
                            .font(.body)
                    )
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            pulseScale = 1.05
                        }
                    }
            }

            // Phase number
            Text("\(phase)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(phaseColor)
                .offset(y: 34)
        }
    }
}

private struct Arrow: View {
    let isUnlocked: Bool

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.caption2)
            .foregroundColor(isUnlocked ? .white.opacity(0.5) : .white.opacity(0.2))
    }
}

// MARK: - Benefit Row

private struct BenefitRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Subscription Option

private struct SubscriptionOption: View {
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool
    let action: () -> Void

    private var perMonthText: String? {
        guard isBestValue,
              let subscription = product.subscription,
              subscription.subscriptionPeriod.unit == .year else {
            return nil
        }
        let monthly = product.price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: monthly as NSDecimalNumber)
    }

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.headline)
                            .foregroundColor(.white)

                        if isBestValue {
                            Text("SAVE 44%")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }

                    if let perMonth = perMonthText {
                        Text("Just \(perMonth)/month")
                            .font(.caption)
                            .foregroundColor(.green.opacity(0.9))
                    } else {
                        Text(product.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.white.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

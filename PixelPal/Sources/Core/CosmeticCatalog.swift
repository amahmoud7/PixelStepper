import Foundation

/// Static registry of all available cosmetic items.
struct CosmeticCatalog {

    // MARK: - Full Catalog

    static let all: [CosmeticItem] = backgrounds + hats + accessories + skins

    // MARK: - Backgrounds (10)

    static let backgrounds: [CosmeticItem] = [
        CosmeticItem(
            id: "bg_softglow", name: "Soft Glow", category: .background, rarity: .common,
            price: 100, assetName: "cosmetic_bg_softglow",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "bg_ocean", name: "Ocean Wave", category: .background, rarity: .common,
            price: 150, assetName: "cosmetic_bg_ocean",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "bg_sunset", name: "Sunset Blaze", category: .background, rarity: .uncommon,
            price: 300, assetName: "cosmetic_bg_sunset",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "bg_forest", name: "Forest Mist", category: .background, rarity: .uncommon,
            price: 300, assetName: "cosmetic_bg_forest",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "bg_electric", name: "Electric Pulse", category: .background, rarity: .rare,
            price: 600, assetName: "cosmetic_bg_electric",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "bg_cherry", name: "Cherry Blossom", category: .background, rarity: .rare,
            price: 600, assetName: "cosmetic_bg_cherry",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "bg_galaxy", name: "Galaxy Swirl", category: .background, rarity: .epic,
            price: 1200, assetName: "cosmetic_bg_galaxy",
            requiresPremium: true, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "bg_northern", name: "Northern Lights", category: .background, rarity: .epic,
            price: 1200, assetName: "cosmetic_bg_northern",
            requiresPremium: true, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "bg_golden", name: "Golden Flame", category: .background, rarity: .legendary,
            price: 2500, assetName: "cosmetic_bg_golden",
            requiresPremium: false, requiredPhase: 3, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "bg_void", name: "Void Portal", category: .background, rarity: .legendary,
            price: 2500, assetName: "cosmetic_bg_void",
            requiresPremium: false, requiredPhase: 4, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
    ]

    // MARK: - Hats (12)

    static let hats: [CosmeticItem] = [
        CosmeticItem(
            id: "hat_baseball", name: "Baseball Cap", category: .hat, rarity: .common,
            price: 100, assetName: "cosmetic_hat_baseball",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "hat_beanie", name: "Beanie", category: .hat, rarity: .common,
            price: 100, assetName: "cosmetic_hat_beanie",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "hat_headband", name: "Headband", category: .hat, rarity: .common,
            price: 150, assetName: "cosmetic_hat_headband",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "hat_catears", name: "Cat Ears", category: .hat, rarity: .uncommon,
            price: 300, assetName: "cosmetic_hat_catears",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "hat_crown", name: "Crown", category: .hat, rarity: .uncommon,
            price: 400, assetName: "cosmetic_hat_crown",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "hat_wizard", name: "Wizard Hat", category: .hat, rarity: .rare,
            price: 700, assetName: "cosmetic_hat_wizard",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "hat_viking", name: "Viking Helmet", category: .hat, rarity: .rare,
            price: 700, assetName: "cosmetic_hat_viking",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "hat_halo", name: "Halo", category: .hat, rarity: .epic,
            price: 1500, assetName: "cosmetic_hat_halo",
            requiresPremium: true, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "hat_firecrown", name: "Fire Crown", category: .hat, rarity: .epic,
            price: 1500, assetName: "cosmetic_hat_firecrown",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 30, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "hat_party", name: "Party Hat", category: .hat, rarity: .seasonal,
            price: 500, assetName: "cosmetic_hat_party",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: true, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "hat_santa", name: "Pixel Santa", category: .hat, rarity: .seasonal,
            price: 800, assetName: "cosmetic_hat_santa",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: true,
            availableFrom: makeDateComponents(month: 12, day: 1),
            availableTo: makeDateComponents(month: 12, day: 31)
        ),
        CosmeticItem(
            id: "hat_legendary", name: "Legendary Helm", category: .hat, rarity: .legendary,
            price: 3000, assetName: "cosmetic_hat_legendary",
            requiresPremium: false, requiredPhase: 4, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
    ]

    // MARK: - Accessories (8)

    static let accessories: [CosmeticItem] = [
        CosmeticItem(
            id: "acc_scarf", name: "Scarf", category: .accessory, rarity: .common,
            price: 100, assetName: "cosmetic_acc_scarf",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "acc_backpack", name: "Backpack", category: .accessory, rarity: .common,
            price: 150, assetName: "cosmetic_acc_backpack",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "acc_sunglasses", name: "Sunglasses", category: .accessory, rarity: .uncommon,
            price: 300, assetName: "cosmetic_acc_sunglasses",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "acc_wings_small", name: "Wings", category: .accessory, rarity: .rare,
            price: 800, assetName: "cosmetic_acc_wings_small",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "acc_shield", name: "Shield", category: .accessory, rarity: .rare,
            price: 800, assetName: "cosmetic_acc_shield",
            requiresPremium: true, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "acc_lightning", name: "Lightning Bolt", category: .accessory, rarity: .epic,
            price: 1500, assetName: "cosmetic_acc_lightning",
            requiresPremium: true, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "acc_angel_wings", name: "Angel Wings", category: .accessory, rarity: .legendary,
            price: 3000, assetName: "cosmetic_acc_angel_wings",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 100, requiredTotalSteps: 0,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
        CosmeticItem(
            id: "acc_sword", name: "Pixel Sword", category: .accessory, rarity: .legendary,
            price: 3000, assetName: "cosmetic_acc_sword",
            requiresPremium: false, requiredPhase: 1, requiredStreak: 0, requiredTotalSteps: 50_000,
            isLimited: false, availableFrom: nil, availableTo: nil
        ),
    ]

    // MARK: - Skins

    /// Original full-character skins only; licensed characters violate App Review 5.2.
    static let skins: [CosmeticItem] = []

    // MARK: - Lookups

    static func item(id: String) -> CosmeticItem? {
        all.first { $0.id == id }
    }

    static func items(for category: CosmeticCategory) -> [CosmeticItem] {
        all.filter { $0.category == category }
    }

    /// Returns items the user can currently see (filters out off-season limited items).
    static func availableItems(isPremium: Bool, phase: Int, streak: Int, totalSteps: Int) -> [CosmeticItem] {
        all.filter { item in
            // Filter out off-season limited items
            if item.isLimited, !isInSeason(item) {
                return false
            }
            return true
        }
    }

    /// Returns currently in-season limited items.
    static func currentSeasonalItems() -> [CosmeticItem] {
        all.filter { $0.isLimited && isInSeason($0) }
    }

    // MARK: - Featured Rotation

    /// Returns 3 featured items that rotate every 3 days.
    /// Premium users see next rotation 24hrs early.
    static func featuredItems(isPremium: Bool) -> [CosmeticItem] {
        let calendar = Calendar.current
        let now = Date()

        // Calculate rotation period (3-day blocks since a fixed epoch)
        guard let epoch = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) else {
            return Array(all.prefix(3))
        }
        let daysSinceEpoch = calendar.dateComponents([.day], from: epoch, to: now).day ?? 0

        // Premium users see next rotation 24hrs early
        let effectiveDays = isPremium ? daysSinceEpoch + 1 : daysSinceEpoch
        let rotationIndex = effectiveDays / 3

        // Use rotation index as seed for deterministic selection
        var rng = SeededRNG(seed: UInt64(bitPattern: Int64(rotationIndex &* 2654435761)))

        // Pool: non-limited items with rarity uncommon or higher
        let pool = all.filter { !$0.isLimited && $0.rarity != .common }
        guard pool.count >= 3 else { return Array(pool.prefix(3)) }

        var shuffled = pool.shuffled(using: &rng)
        // Ensure variety — pick from different categories if possible
        var result: [CosmeticItem] = []
        var usedCategories = Set<CosmeticCategory>()

        for item in shuffled {
            if result.count >= 3 { break }
            if result.count < 2 && usedCategories.contains(item.category) { continue }
            result.append(item)
            usedCategories.insert(item.category)
        }

        // Fill remaining if we couldn't get category variety
        if result.count < 3 {
            for item in shuffled where !result.contains(where: { $0.id == item.id }) {
                result.append(item)
                if result.count >= 3 { break }
            }
        }

        return result
    }

    /// Time until next featured rotation.
    static func timeUntilNextRotation() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        guard let epoch = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) else {
            return 3 * 24 * 3600
        }
        let daysSinceEpoch = calendar.dateComponents([.day], from: epoch, to: now).day ?? 0
        let currentBlock = daysSinceEpoch / 3
        let nextBlockStart = (currentBlock + 1) * 3

        guard let nextDate = calendar.date(byAdding: .day, value: nextBlockStart, to: epoch) else {
            return 3 * 24 * 3600
        }
        return nextDate.timeIntervalSince(now)
    }

    // MARK: - Helpers

    private static func isInSeason(_ item: CosmeticItem) -> Bool {
        guard item.isLimited else { return true }

        // Items with no date range are always available (e.g. Party Hat)
        guard let from = item.availableFrom, let to = item.availableTo else {
            return true
        }

        let now = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: now)
        let currentDay = calendar.component(.day, from: now)
        let fromMonth = calendar.component(.month, from: from)
        let fromDay = calendar.component(.day, from: from)
        let toMonth = calendar.component(.month, from: to)
        let toDay = calendar.component(.day, from: to)

        if fromMonth == toMonth {
            return currentMonth == fromMonth && currentDay >= fromDay && currentDay <= toDay
        }
        // Cross-month range
        if currentMonth == fromMonth {
            return currentDay >= fromDay
        }
        if currentMonth == toMonth {
            return currentDay <= toDay
        }
        return currentMonth > fromMonth && currentMonth < toMonth
    }
}

// MARK: - Seeded RNG for Catalog

private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

// MARK: - Date Helper

/// Creates a Date with just month and day components for seasonal comparison.
private func makeDateComponents(month: Int, day: Int) -> Date {
    var components = DateComponents()
    components.year = Calendar.current.component(.year, from: Date())
    components.month = month
    components.day = day
    return Calendar.current.date(from: components) ?? Date()
}

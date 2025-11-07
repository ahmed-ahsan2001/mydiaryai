import Foundation
internal import Combine

@MainActor
final class SubscriptionService: ObservableObject {
    @Published private(set) var isSubscribed: Bool = false
    @Published private(set) var trialEndsAt: Date

    private let trialKey = "trial_start_date"

    init(now: Date = Date()) {
        if let saved = UserDefaults.standard.object(forKey: trialKey) as? Date {
            trialEndsAt = Calendar.current.date(byAdding: .day, value: 7, to: saved) ?? now
        } else {
            UserDefaults.standard.set(now, forKey: trialKey)
            trialEndsAt = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        }
        // RevenueCat integration would update isSubscribed accordingly.
    }

    var isTrialActive: Bool { Date() < trialEndsAt }
    var isLocked: Bool { !(isSubscribed || isTrialActive) }

    func restorePurchases() async {
        // TODO: Hook into RevenueCat.restorePurchases()
        // For now, no-op.
    }

    func loadOfferings() async -> [String] {
        // TODO: Hook into RevenueCat offerings
        return ["Monthly", "Yearly"]
    }

    func subscribe(productId: String) async throws {
        // TODO: Hook into RevenueCat purchase flow
        // Simulate success for development
        isSubscribed = true
    }
}



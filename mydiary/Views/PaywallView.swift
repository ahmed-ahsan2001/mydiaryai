import SwiftUI

struct PaywallView: View {
    @ObservedObject var subscriptionService: SubscriptionService
    @State private var offerings: [String] = []
    @State private var selected: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Unlock MyDiary AI")
                .font(.title.bold()).foregroundColor(.appText)
            Text("Continue journaling after your 7-day free trial. Cancel anytime.")
                .multilineTextAlignment(.center)
                .foregroundColor(.appText.opacity(0.7))
            ForEach(offerings, id: \.self) { offer in
                Button(action: { selected = offer; Task { try? await subscriptionService.subscribe(productId: offer) } }) {
                    HStack { Text(offer); Spacer(); Image(systemName: "checkmark.circle") }
                        .padding().background(RoundedRectangle(cornerRadius: 14).fill(.white))
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                }
            }
            Button("Restore Purchases") { Task { await subscriptionService.restorePurchases() } }
                .padding(.top, 8)
        }
        .padding()
        .background(Color.appBackground.ignoresSafeArea())
        .task { offerings = await subscriptionService.loadOfferings() }
    }
}



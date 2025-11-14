import SwiftUI

struct ProfileView: View {
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var subscriptionService: SubscriptionService
    @State private var notificationsEnabled = true
    @State private var aiInsightsEnabled = true
    @State private var shareUsageEnabled = true
    @State private var showThemeSelection = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {

                // MARK: - Header
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)
                        .overlay(Text("M").font(.title2.bold()).foregroundColor(.white))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mohammad Ahmed Ahsan")
                            .font(.title3.bold())
                            .foregroundColor(.appText)
                        Text("ahmed.ahsan@dubizzlelabs.com")
                            .font(.subheadline)
                            .foregroundColor(.appText.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // MARK: - Account Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("ACCOUNT")
                        .font(.caption)
                        .foregroundColor(.appText.opacity(0.5))

                    HStack {
                        Label("Subscription & Billing", systemImage: "creditcard")
                            .font(.body)
                            .foregroundColor(.appText)
                        Spacer()
                        Text("Free Trial: 6 days left")
                            .font(.subheadline)
                            .foregroundColor(.appText.opacity(0.6))
                    }
                }
                .padding(.horizontal)

                // MARK: - Preferences Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("APP PREFERENCES")
                        .font(.caption)
                        .foregroundColor(.appText.opacity(0.5))

                    themeSelectionRow
                    preferenceRow(icon: "textformat.size", title: "Font Style", subtitle: "Fredoka")

                    toggleRow(icon: "bell", title: "Notifications", isOn: $notificationsEnabled)
                    toggleRow(icon: "brain.head.profile", title: "AI Questions & Insights", isOn: $aiInsightsEnabled)
                    toggleRow(icon: "chart.bar", title: "Share Usage Analytics", isOn: $shareUsageEnabled)
                }
                .padding(.horizontal)

                // MARK: - About Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("ABOUT")
                        .font(.caption)
                        .foregroundColor(.appText.opacity(0.5))

                    aboutRow(icon: "shield", title: "Privacy Policy")
                    aboutRow(icon: "doc.text", title: "Terms & Conditions")
                    aboutRow(icon: "chevron.left.slash.chevron.right", title: "Open Source Licenses")
                    aboutRow(icon: "questionmark.circle", title: "Contact Us")
                    aboutRow(icon: "star", title: "Rate & Review Our App")
                    aboutRow(icon: "square.and.arrow.up", title: "Share Our App")
                    aboutRow(icon: "info.circle", title: "Credits")
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showThemeSelection) {
            NavigationStack {
                ThemeSelectionView(
                    themeManager: themeManager,
                    subscriptionService: subscriptionService
                )
            }
        }
    }

    // MARK: - Components
    
    private var themeSelectionRow: some View {
        HStack {
            Label("Theme", systemImage: "paintpalette")
                .font(.body)
                .foregroundColor(.appText)
            Spacer()
            HStack(spacing: 8) {
                Text(themeManager.currentTheme.displayName)
                    .font(.subheadline)
                    .foregroundColor(.appText.opacity(0.7))
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.appText.opacity(0.5))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showThemeSelection = true
        }
    }
    
    private func preferenceRow(icon: String, title: String, subtitle: String) -> some View {
        HStack {
            Label(title + ": " + subtitle, systemImage: icon)
                .font(.body)
                .foregroundColor(.appText)
            Spacer()
        }
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.body)
                .foregroundColor(.appText)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.green)
        }
    }

    private func aboutRow(icon: String, title: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.body)
                .foregroundColor(.appText)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { print("\(title) tapped") }
    }
}


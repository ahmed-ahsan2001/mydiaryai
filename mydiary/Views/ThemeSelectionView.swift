import SwiftUI

struct ThemeSelectionView: View {
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Choose Your Theme")
                    .font(.title2.bold())
                    .foregroundColor(.appHighlight)
                    .padding(.horizontal)
                
                Text("Personalize your diary experience with beautiful color themes")
                    .font(.subheadline)
                    .foregroundColor(.appText.opacity(0.7))
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 20) {
                    ForEach(AppThemeType.allCases) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: themeManager.currentTheme == theme,
                            isLocked: !themeManager.canUseTheme(theme),
                            onTap: {
                                handleThemeSelection(theme)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Themes")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView(subscriptionService: subscriptionService)
        }
    }
    
    private func handleThemeSelection(_ theme: AppThemeType) {
        if themeManager.setTheme(theme) {
            // Theme set successfully
        } else {
            // Theme is locked, show paywall
            showPaywall = true
        }
    }
}

private struct ThemeCard: View {
    let theme: AppThemeType
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Color Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.colorPalette.softLinen,
                                    theme.colorPalette.warmCream,
                                    theme.colorPalette.slateBlue,
                                    theme.colorPalette.deepNavy
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                    
                    if isLocked {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.4))
                            
                            VStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                Text("Premium")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.3))
                                    )
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
                
                // Theme Info
                VStack(spacing: 4) {
                    HStack {
                        Text(theme.displayName)
                            .font(.headline)
                            .foregroundColor(.appText)
                        Spacer()
                    }
                    
                    if theme.isPremium {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("Premium")
                                .font(.caption)
                                .foregroundColor(.appText.opacity(0.6))
                            Spacer()
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? theme.colorPalette.accent : Color.clear,
                        lineWidth: 3
                    )
            )
        }
        .buttonStyle(.plain)
    }
}



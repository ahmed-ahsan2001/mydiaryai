//
//  ContentView.swift
//  mydiary
//
//  Created by Ahmed Ahsan on 30/10/2025.
//

import SwiftUI

struct ContentView: View {
    private let store = DiaryStore()
    @StateObject private var subscriptionService = SubscriptionService()
    @StateObject private var themeManager: ThemeManager
    @State private var showOnboarding = UserDefaults.standard.bool(forKey: "has_onboarded") == false
    @State private var showLaunchScreen = true

    init() {
        let subService = SubscriptionService()
        let themeMgr = ThemeManager(subscriptionService: subService)
        _subscriptionService = StateObject(wrappedValue: subService)
        _themeManager = StateObject(wrappedValue: themeMgr)
    }

    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchScreenView()
            } else if showOnboarding {
                OnboardingView {
                    UserDefaults.standard.set(true, forKey: "has_onboarded")
                    showOnboarding = false
                }
            } else {
                HomeView(store: store, themeManager: themeManager, subscriptionService: subscriptionService)
                    .environmentObject(themeManager)
            }
        }
        .onAppear {
            ThemeManager.setGlobal(themeManager)
            startLaunchTimer()
        }
        .onChange(of: themeManager.currentTheme) { _ in
            ThemeManager.setGlobal(themeManager)
        }
    }

    private func startLaunchTimer() {
        guard showLaunchScreen else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.35)) {
                showLaunchScreen = false
            }
        }
    }
}

//
//  ContentView.swift
//  mydiary
//
//  Created by Ahmed Ahsan on 30/10/2025.
//

import SwiftUI

struct ContentView: View {
    private let store = DiaryStore()
    @State private var showOnboarding = UserDefaults.standard.bool(forKey: "has_onboarded") == false
    @State private var showLaunchScreen = true

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
                HomeView(store: store)
            }
        }
        .onAppear(perform: startLaunchTimer)
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

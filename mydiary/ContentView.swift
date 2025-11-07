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

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView { UserDefaults.standard.set(true, forKey: "has_onboarded"); showOnboarding = false }
            } else {
                HomeView(store: store)
            }
        }
    }
}

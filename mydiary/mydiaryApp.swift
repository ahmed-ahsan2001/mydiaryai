//
//  mydiaryApp.swift
//  mydiary
//
//  Created by Ahmed Ahsan on 30/10/2025.
//

import SwiftUI
import CoreData

@main
struct mydiaryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(AppTheme.accent)
                .background(AppTheme.background)
                .preferredColorScheme(.light)
        }
    }
}

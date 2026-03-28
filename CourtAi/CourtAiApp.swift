//
//  CourtAiApp.swift
//  CourtAi
//

import SwiftUI

@main
struct CourtAiApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                CourtView()
            } else {
                OnboardingView()
            }
        }
    }
}

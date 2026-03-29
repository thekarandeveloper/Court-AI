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
            Group {
                if hasCompletedOnboarding {
                    CourtView()
                } else {
                    OnboardingView()
                }
            }
            .onAppear {
                print("📁 Documents:", FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path)
            }
        }
    }
}

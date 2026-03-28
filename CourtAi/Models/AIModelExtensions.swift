//
//  AIModelExtensions.swift
//  CourtAi
//
//  Shared display helpers for AIService.AIModel — used across views.
//

import SwiftUI

extension AIService.AIModel {
    var displayName: String {
        switch self {
        case .gemini: return "Gemini"
        case .grok:   return "LLaMA"
        case .claude: return "Claude"
        }
    }
    var chipColor: Color {
        switch self {
        case .gemini: return Color(red: 0.09, green: 0.56, blue: 0.90)
        case .grok:   return Color(red: 0.52, green: 0.32, blue: 0.88)
        case .claude: return Color(red: 0.84, green: 0.46, blue: 0.10)
        }
    }
}

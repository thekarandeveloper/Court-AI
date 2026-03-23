//
//  AgentSession.swift
//  PromptCircle
//
//  Council Session data models
//

import Foundation

enum SessionPhase: String {
    case opening    = "Opening Stance"
    case discussion = "Cross-Examination"
    case verdict    = "Verdict"

    var icon: String {
        switch self {
        case .opening:    return "person.3.fill"
        case .discussion: return "arrow.triangle.2.circlepath"
        case .verdict:    return "checkmark.seal.fill"
        }
    }
}

struct SessionMessage: Identifiable {
    var id = UUID()
    let model: AIService.AIModel   // reuse AIService.AIModel for routing
    var content: String
    let phase: SessionPhase
    var isThinking: Bool
}

//
//  TrialManager.swift
//  CourtAi
//
//  Tracks free trial usage. First 5 court sessions use developer keys.
//  After that, user must provide their own keys.
//

import Foundation

enum TrialManager {
    static let maxFreeUses = 5
    private static let key = "courtai_trial_uses"

    static var usesRemaining: Int {
        max(0, maxFreeUses - usesConsumed)
    }

    static var isTrialActive: Bool {
        usesRemaining > 0
    }

    static var hasOwnKeys: Bool {
        APIKeys.allSet()
    }

    /// Call once per completed court session.
    static func recordUse() {
        UserDefaults.standard.set(usesConsumed + 1, forKey: key)
    }

    static var usesConsumed: Int {
        UserDefaults.standard.integer(forKey: key)
    }
}

//
//  SessionLogger.swift
//  CourtAi
//
//  Appends every completed session to Documents/court_sessions.json.
//  Read this file for research analysis — each entry is one full deliberation.
//

import Foundation

struct SessionLog: Codable {
    let id:             String   // UUID
    let timestamp:      String   // ISO-8601
    let question:       String
    let forModel:       String
    let againstModel:   String
    let judgeModel:     String

    // Hearing 1 — independent stances
    let h1ForArg:       String
    let h1ForEvidence:  String
    let h1AgArg:        String
    let h1AgEvidence:   String

    // Hearing 2 — cross-examination
    let h2ForArg:       String
    let h2ForEvidence:  String
    let h2AgArg:        String
    let h2AgEvidence:   String

    let verdict:        String
    let verdictSide:    String   // "YES", "NO", or "UNKNOWN"
    let durationSeconds: Double
}

enum SessionLogger {

    private static let fileName = "court_sessions.json"

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    static func log(
        question: String,
        forModel: String, againstModel: String, judgeModel: String,
        h1ForArg: String, h1ForEvidence: String,
        h1AgArg:  String, h1AgEvidence:  String,
        h2ForArg: String, h2ForEvidence: String,
        h2AgArg:  String, h2AgEvidence:  String,
        verdict:  String,
        duration: TimeInterval
    ) {
        let entry = SessionLog(
            id:              UUID().uuidString,
            timestamp:       ISO8601DateFormatter().string(from: Date()),
            question:        question,
            forModel:        forModel,
            againstModel:    againstModel,
            judgeModel:      judgeModel,
            h1ForArg:        h1ForArg,
            h1ForEvidence:   h1ForEvidence,
            h1AgArg:         h1AgArg,
            h1AgEvidence:    h1AgEvidence,
            h2ForArg:        h2ForArg,
            h2ForEvidence:   h2ForEvidence,
            h2AgArg:         h2AgArg,
            h2AgEvidence:    h2AgEvidence,
            verdict:         verdict,
            verdictSide:     extractSide(from: verdict),
            durationSeconds: duration
        )

        var all = loadAll()
        all.append(entry)

        guard let data = try? JSONEncoder().encode(all) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Private

    private static func loadAll() -> [SessionLog] {
        guard let data = try? Data(contentsOf: fileURL),
              let logs = try? JSONDecoder().decode([SessionLog].self, from: data)
        else { return [] }
        return logs
    }

    /// Parses "The court rules — YES: ..." → "YES"
    private static func extractSide(from verdict: String) -> String {
        let upper = verdict.uppercased()
        if let range = upper.range(of: "—") {
            let after = upper[range.upperBound...].trimmingCharacters(in: .whitespaces)
            if after.hasPrefix("YES") { return "YES" }
            if after.hasPrefix("NO")  { return "NO"  }
        }
        // Fallback: scan anywhere in string
        if upper.contains(" YES") || upper.hasPrefix("YES") { return "YES" }
        if upper.contains(" NO:")  || upper.hasPrefix("NO")  { return "NO"  }
        return "UNKNOWN"
    }
}

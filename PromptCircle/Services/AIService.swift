//
//  AIService.swift
//  PromptCircle
//
//  Created by Karan Kumar on 06/10/25.
//


import Foundation

final class AIService {
    static let shared = AIService()
    private init() {}
    
    // MARK: - Gemini API
    private let geminiKey = "AIzaSyAEV7FccbSqrW2evxgfw5W6xFwHi9JuCeA"
    private let geminiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    struct GeminiResponse: Codable {
        let candidates: [Candidate]?
    }
    
    struct Candidate: Codable {
        let content: Content
    }
    
    struct Content: Codable {
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String?
    }
    
    func generateGemini(prompt: String) async throws -> String {
        guard let url = URL(string: "\(geminiURL)?key=\(geminiKey)") else {
            throw URLError(.badURL)
        }
        
        let payload: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: payload)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let (responseData, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: responseData)
        return decoded.candidates?.first?.content.parts.first?.text ?? "No response"
    }
    func generateGemini2(prompt: String) async throws -> String {
        guard let url = URL(string: "\(geminiURL)?key=\("AIzaSyDVNI-ylXHvkBTkRrjAMMXallzqHX7JH1M")") else {
            throw URLError(.badURL)
        }
        
        let payload: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: payload)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let (responseData, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: responseData)
        return decoded.candidates?.first?.content.parts.first?.text ?? "No response"
    }
    // MARK: - Grok (Groq) API
    private let grokKey = "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"
    private let grokURL = "https://api.groq.com/openai/v1/chat/completions"
    
    struct GrokResponse: Codable {
        let choices: [Choice]
        struct Choice: Codable {
            let message: Message
            struct Message: Codable {
                let content: String
            }
        }
    }
    
    func generateGrok(prompt: String, model: String = "llama-3.3-70b-versatile") async throws -> String {
        guard let url = URL(string: grokURL) else {
            throw URLError(.badURL)
        }
        
        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: payload)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(grokKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(GrokResponse.self, from: responseData)
        return decoded.choices.first?.message.content ?? "No response"
    }
//    func fetchClaudeResponse(prompt: String) async throws -> String {
//        guard let url = URL(string: "https://api.poe.com/v1/chat/completions") else {
//            return "Error: Invalid URL"
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("Bearer pzVqTNn7ShhvJDkB16Uk3opn74TxxoOWYL2xNwRUZeQ", forHTTPHeaderField: "Authorization")
//
//        let body: [String: Any] = [
//            "model": "Claude-Sonnet-4",
//            "messages": [
//                ["role": "user", "content": prompt]
//            ]
//        ]
//
//        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
//
//        let (data, response) = try await URLSession.shared.data(for: request)
//        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
//            let text = String(data: data, encoding: .utf8) ?? ""
//            print("Status Code: \(httpResponse.statusCode), Body: \(text)")
//            return "Error: Bad response from server"
//        }
//
//        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//              let choices = json["choices"] as? [[String: Any]],
//              let firstChoice = choices.first,
//              let message = firstChoice["message"] as? [String: Any],
//              let content = message["content"] as? String else {
//            return "Error: Could not parse response"
//        }
//
//        return content
//    }
    // MARK: - General interface
    enum AIModel: String, CaseIterable {
        case gemini = "Gemini"
        case grok = "Grok"
        case claude = "Claude-Sonnet-4"
    }
    
    func getAIResponse(for model: AIModel, prompt: String) async -> String {
        do {
            switch model {
            case .gemini:
                return try await generateGemini(prompt: prompt)
            case .grok:
                return try await generateGrok(prompt: prompt)
            case .claude:
                return try await generateGemini2(prompt: prompt)
            }
        } catch {
            return "API error: \(error.localizedDescription)"
        }
    }
}

//
//  Message.swift
//  PromptCircle
//
//  Created by Karan Kumar on 06/10/25.
//

import Foundation

enum AIModel: String, CaseIterable, Codable, Equatable {
    case grok = "Grok"
    case gemini = "Gemini"
    case claude = "Claude"
}

enum SenderType: Codable, Equatable {
    case user
    case ai(model: AIModel)
    
    private enum CodingKeys: String, CodingKey {
        case type, model
    }
    
    private enum SenderTypeName: String, Codable {
        case user, ai
    }
    
    // Encode
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .user:
            try container.encode(SenderTypeName.user, forKey: .type)
        case .ai(let model):
            try container.encode(SenderTypeName.ai, forKey: .type)
            try container.encode(model, forKey: .model)
        }
    }
    
    // Decode
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(SenderTypeName.self, forKey: .type)
        
        switch type {
        case .user:
            self = .user
        case .ai:
            let model = try container.decode(AIModel.self, forKey: .model)
            self = .ai(model: model)
        }
    }
}

struct Message: Identifiable, Codable {
    let id: UUID
    let sender: SenderType
    let content: String
    let timestamp: Date
    var isCollapsed: Bool
    
    init(id: UUID = UUID(), sender: SenderType, content: String, timestamp: Date = Date(), isCollapsed: Bool = false) {
        self.id = id
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
        self.isCollapsed = isCollapsed
    }
}

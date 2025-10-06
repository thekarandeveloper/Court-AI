//
//  ChatView.swift
//  PromptCircle
//
//  Created by Karan Kumar on 06/10/25.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var vm = ChatViewModel()
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    ForEach(vm.messages) { message in
                        MessageBubble(message: message)
                    }
                }
            }
            
            HStack {
                TextField("Ask something...", text: $vm.userInput)
                    .textFieldStyle(.roundedBorder)
                
                Button("Send") {
                    Task {
                        await vm.sendMessage()
                    }
                }
            }
            .padding()
        }
    }
}

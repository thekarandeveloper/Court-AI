//
//  CustomNavbar.swift
//  PromptCircle
//
//  Created by Karan Kumar on 06/10/25.
//
import SwiftUI

struct CustomNavbar: View {
    var body: some View {
        HStack {
            // Left: Profile / Menu button
            Button(action: {
                print("Profile tapped")
            }) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.blue, .blue.opacity(0.2))
                    .shadow(radius: 1)
            }
            
            Spacer()
            
            // Center: Greeting / Title
            VStack(spacing: 2) {
                Text("Hi, Karan")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Discuss Anything")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Right: Notification button
            Button(action: {
                print("Notification tapped")
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                    
                    // Notification badge
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 6, y: -4)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
       
    }
}

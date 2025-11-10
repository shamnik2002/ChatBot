//
//  ChatBotApp.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/16/25.
//

import SwiftUI
import SwiftData

@main
struct ChatBotApp: App {
    
    var body: some Scene {
        WindowGroup {
            MainTabView(viewModel: MainTabViewModel())
        }.modelContainer(for: [ConversationModel.self, ChatMessageModel.self, UsageModel.self])
    }
}

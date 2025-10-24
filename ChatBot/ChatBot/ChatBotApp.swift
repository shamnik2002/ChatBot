//
//  ChatBotApp.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/16/25.
//

import SwiftUI

@main
struct ChatBotApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewModel(appStore: AppStore()))
        }
    }
}

//
//  MainTabView.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/24/25.
//
import SwiftUI
import Combine
import SwiftData

final class MainTabViewModel: ObservableObject {
    
    init() {
        
    }
}

struct MainTabView: View {
    
    @Environment(\.modelContext) var modelContext
    @StateObject var viewModel: MainTabViewModel
    
    var body: some View {
        TabView {
            HomeView(homeViewModel: HomeViewModel(modelContext: modelContext))
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}



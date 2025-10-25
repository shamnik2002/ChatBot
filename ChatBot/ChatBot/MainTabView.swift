//
//  MainTabView.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/24/25.
//
import SwiftUI
import Combine

final class MainTabViewModel: ObservableObject {
    private(set) var appStore: AppStore
    
    init(appStore: AppStore) {
        self.appStore = appStore
    }
}

struct MainTabView: View {
    
    @StateObject var viewModel: MainTabViewModel
    
    var body: some View {
        TabView {
            HomeView(homeViewModel: HomeViewModel(appStore: viewModel.appStore))
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



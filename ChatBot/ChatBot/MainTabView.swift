//
//  MainTabView.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/24/25.
//
import SwiftUI
import Combine

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
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



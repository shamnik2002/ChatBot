//
//  HomeView.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/24/25.
//
import SwiftUI
import Combine

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ConversationListView()
            .navigationTitle("Home")
        }
    }
}

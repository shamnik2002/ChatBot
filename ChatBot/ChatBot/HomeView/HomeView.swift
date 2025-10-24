//
//  HomeView.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/24/25.
//
import SwiftUI
import Combine

struct HomeView: View {
    @State private var isShowingDetail = false
    
    var body: some View {
        NavigationStack {
            ConversationListView()
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(id: "New", placement: .topBarTrailing) {
                    NavigationLink(destination: ContentView(viewModel: ContentViewModel(appStore: AppStore.shared))) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
    }
}

//
//  HomeView.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/24/25.
//
import SwiftUI
import Combine

struct HomeView: View {

    @StateObject var homeViewModel: HomeViewModel
    
    var body: some View {
        NavigationStack {
            ConversationListView(viewModel: ConversationListViewModel(appStore: homeViewModel.appStore))
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(id: "New", placement: .topBarTrailing) {
                    NavigationLink(destination: ChatContainerView(viewModel: ChatContainerViewModel(appStore: homeViewModel.appStore, conversationDataModel: homeViewModel.createNewConversation()))) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
    }
}

//
//  ConversationListView.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/24/25.
//
import SwiftUI
import Combine


struct Conversation: Identifiable, Hashable {
    let id: String
    let title: String
}

final class ConversationListViewModel: ObservableObject {
    @Published var items: [Conversation] = []
    
    init() {
        items = mockConversationList()
    }
    
}
struct ConversationListView: View {
    
    @StateObject var viewModel = ConversationListViewModel()
    
    var body: some View {
        List(viewModel.items) { item in
            
            NavigationLink(value: item) {
                Text(item.title)
            }
        }.navigationDestination(for: Conversation.self) { item in
            ContentView(viewModel: ContentViewModel(appStore: AppStore.shared))
        }
    }
}

func mockConversationList() -> [Conversation] {
    
    var conversations = [Conversation]()
    for str in  randomStringGenerator(count: 20, minStringLength: 25 ,maxStringLength: 50) {
        let convo = Conversation(id: UUID().uuidString, title: str)
        conversations.append(convo)
    }
    return conversations
}

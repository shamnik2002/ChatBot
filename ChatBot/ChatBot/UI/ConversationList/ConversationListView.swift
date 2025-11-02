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
    @Published var items: [ConversationDataModel] = []
    
    private var cancellables = Set<AnyCancellable>()
    private(set) var appStore: AppStore
    init(appStore: AppStore) {
        self.appStore = appStore
//        items = mockConversationList()
        self.appStore.conversationState.conversationListPublisher
            .receive(on: RunLoop.main)
            .sink {[weak self] conversationList in
                guard !conversationList.isEmpty else { return }
                self?.items = conversationList
            }.store(in: &cancellables)
    }
    
    func fetchConversations() {
        let getConvo = GetConversationList()
        appStore.dispacther.dispatch(getConvo)
    }

}

struct ConversationListView: View {
    
    @StateObject var viewModel:ConversationListViewModel
    
    var body: some View {
        List(viewModel.items) { item in
            
            NavigationLink(value: item) {
                Text(item.title)
            }
        }.navigationDestination(for: ConversationDataModel.self) { item in
            ChatContainerView(viewModel: ChatContainerViewModel(appStore: viewModel.appStore, conversationDataModel: item))
        }.onAppear {
            viewModel.fetchConversations()
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

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
        // Listen list data updates
        self.appStore.conversationState.conversationListPublisher
            .receive(on: RunLoop.main)
            .sink {[weak self] conversationList in
                guard !conversationList.isEmpty else { return }
                self?.items = conversationList
            }.store(in: &cancellables)
    }
    
    /// fetchConversations
    /// Create + dispatch get convo list from store/cache
    func fetchConversations() {
        let getConvo = GetConversationList()
        appStore.dispacther.dispatch(getConvo)
    }

    /// deleteConversations
    /// Trigger delete convo action to delete from store/cache
    func deleteConversations(_ conversations: [ConversationDataModel]) {
        let deleteAction = DeleteConversations(conversations: conversations)
        appStore.dispacther.dispatch(deleteAction)
    }
    
    /// editConversation
    /// Trigger edit (rename) action to update convo in store/cache
    func editConversation(_ conversation: ConversationDataModel, title: String) {
        let newConversation = conversation
        newConversation.title = title
        let editAction = EditConversation(conversation: newConversation)
        appStore.dispacther.dispatch(editAction)
    }
}

struct ConversationListView: View {
    
    @StateObject var viewModel:ConversationListViewModel
    @State var showEditAlert = false
    @State var selectedItem: ConversationDataModel?
    @State var editedTitle = ""
    
    var body: some View {
        List {
            ForEach(viewModel.items, id:\.hashValue) { item in
                NavigationLink(value: item) {
                    Text(item.title)
                        .swipeActions(edge: .leading) {
                            Button("Edit") {
                                selectedItem = item
                                showEditAlert = true
                            }.tint(.blue)
                        }
                }
            }
            .onDelete(perform: onDelete(_:))
            .alert("Edit conversation title", isPresented: $showEditAlert) {
                Button("OK", action: onEdit)
                TextField(selectedItem?.title ?? "", text: $editedTitle)
                        .keyboardType(.alphabet)
            }
        }.navigationDestination(for: ConversationDataModel.self) { item in
            ChatContainerView(viewModel: ChatContainerViewModel(appStore: viewModel.appStore, conversationDataModel: item))
        }.onAppear {
            viewModel.fetchConversations()
        }
    }
    
    func onDelete(_ indexSet: IndexSet) {
        let conversations = indexSet.map{viewModel.items[$0]}
        viewModel.deleteConversations(conversations)
    }
    
    func onEdit() {
        guard let convo = selectedItem else {return}
        guard editedTitle != convo.title else {return}
        viewModel.editConversation(convo, title: editedTitle)
        editedTitle = ""
        selectedItem = nil
    }
}

/// Mock convo data generator
func mockConversationList() -> [Conversation] {
    
    var conversations = [Conversation]()
    for str in  randomStringGenerator(count: 20, minStringLength: 25 ,maxStringLength: 50) {
        let convo = Conversation(id: UUID().uuidString, title: str)
        conversations.append(convo)
    }
    return conversations
}

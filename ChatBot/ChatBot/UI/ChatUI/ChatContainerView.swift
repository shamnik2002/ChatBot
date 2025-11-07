//
//  ContentView.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/16/25.
//

import SwiftUI
import Combine

/// ChatContainerView
/// Holds the ChatCollectionViewController
struct ChatContainerView: View {
    @StateObject var viewModel: ChatContainerViewModel
    @State private var text: String = ""
    @State private var isShowingSheet = false
    var body: some View {

        VStack {
                Spacer()
                ChatCollectionViewControllerRepresentable(appStore: viewModel.appStore, conversationDataModel: viewModel.conversationDataModel)
                    .edgesIgnoringSafeArea(.all)
                HStack(spacing: 5) {
                    TextField("Enter your prompt here", text: $text)
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.blue)
                        .onTapGesture {
                            guard !text.isEmpty else {return}
                            self.viewModel.addText(text)
                            text = ""
                        }
                }
                .padding(10)
                .cornerRadius(10)
                .border(Color.secondary, width: 0.5)
            }
            .padding()
            .toolbar {
                ToolbarItem(id: "New", placement: .topBarTrailing) {
                    Button{
                        isShowingSheet = true
                    }label: {
                        Text("Switch Model")
                    }
                    
                }
            }
            .sheet(isPresented: $isShowingSheet) {
                AIModelsListView(viewModel: AIModelsListViewModel(appStore: viewModel.appStore))
                .presentationDetents([.fraction(0.6)])
            }
        
    }
}

///ChatCollectionViewControllerRepresentable
///Allows us to insert UIKit view within SwiftUI
struct ChatCollectionViewControllerRepresentable: UIViewControllerRepresentable {
    
    private let appStore: AppStore
    private let conversationDataModel: ConversationDataModel
    init(appStore: AppStore, conversationDataModel: ConversationDataModel) {
        self.appStore = appStore
        self.conversationDataModel = conversationDataModel
    }
    
    func makeUIViewController(context: Context) -> ChatCollectionViewController {
        let viewModel = ChatCollectionViewModel(appStore: appStore, conversationDataModel: conversationDataModel, dataProcessor: ChatDataProcessor())
        let vc = ChatCollectionViewController(viewModel: viewModel)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ChatCollectionViewController, context: Context) {
    }
    
    typealias UIViewControllerType = ChatCollectionViewController
}

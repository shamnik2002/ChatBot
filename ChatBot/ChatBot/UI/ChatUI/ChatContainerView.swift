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
    var body: some View {

        VStack {
                Spacer()
                ChatCollectionViewControllerRepresentable(appStore: viewModel.appStore, conversationDataModel: viewModel.conversationDataModel, eventHandler: { type in
                    
                    switch type {
                        case .showCharts(let data):
                            viewModel.showChartsView(data: data)
                    }
                })
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
                        viewModel.showAIModelsView()
                    }label: {
                        Text("Switch Model")
                    }
                    
                }
            }
            .sheet(item: $viewModel.ailModelsListViewModel, content: { item in
                AIModelsListView(viewModel: item)
                .presentationDetents([.fraction(0.6)])
            })
            .sheet(item: $viewModel.chartsViewModel, content: { item in
                ChartsView(viewModel: item)
            })
    }
}

///ChatCollectionViewControllerRepresentable
///Allows us to insert UIKit view within SwiftUI
struct ChatCollectionViewControllerRepresentable: UIViewControllerRepresentable {
    
    private let appStore: AppStore
    private let conversationDataModel: ConversationDataModel
    private let eventHandler: ((ChatCollectionViewEventHandler) -> Void)?
    init(appStore: AppStore, conversationDataModel: ConversationDataModel, eventHandler: ((ChatCollectionViewEventHandler) -> Void)? = nil) {
        self.appStore = appStore
        self.conversationDataModel = conversationDataModel
        self.eventHandler = eventHandler
    }
    
    func makeUIViewController(context: Context) -> ChatCollectionViewController {
        let viewModel = ChatCollectionViewModel(appStore: appStore, conversationDataModel: conversationDataModel, dataProcessor: ChatDataProcessor(), eventHandler: eventHandler)
        let vc = ChatCollectionViewController(viewModel: viewModel)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ChatCollectionViewController, context: Context) {
    }
    
    typealias UIViewControllerType = ChatCollectionViewController
}

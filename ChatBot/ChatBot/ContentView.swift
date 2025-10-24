//
//  ContentView.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/16/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject var viewModel: ContentViewModel
    @State private var text: String = ""
    var body: some View {
        VStack {
            Spacer()
            ChatCollectionViewControllerRepresentable(appStore: viewModel.appStore)
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
//            .shadow(color:Color.primary.opacity(0.5), radius: 4, x: 0, y: 2)
        }
        .padding()

    }
}

//#Preview {
//    ContentView(viewModel: ContentViewModel(appStore: <#T##AppStore#>))
//}

struct ChatCollectionViewControllerRepresentable: UIViewControllerRepresentable {
    
    private let appStore: AppStore
    init(appStore: AppStore) {
        self.appStore = appStore
    }
    
    func makeUIViewController(context: Context) -> ChatCollectionViewController {
        let viewModel = ChatCollectionViewModel(appStore: appStore, dataProcessor: ChatDataProcessor())
        let vc = ChatCollectionViewController(viewModel: viewModel)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ChatCollectionViewController, context: Context) {
        
    }
    
    typealias UIViewControllerType = ChatCollectionViewController
    
    
    
}

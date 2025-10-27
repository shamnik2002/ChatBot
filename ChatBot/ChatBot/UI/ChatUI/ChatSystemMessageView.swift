//
//  ChatSystemMessageView.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/27/25.
//
import Combine
import Foundation
import SwiftUI

struct ChatSystemMessageView: View {
    
    struct Constants {
        static let topPadding: CGFloat = 10
        static let bottomPadding:CGFloat = 5
    }
    
    @ObservedObject var viewModel: ChatSystemMessageViewModel
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0){
            Text(viewModel.text)
                .foregroundColor(Color(.lightGray))
                .contentTransition(.opacity)
                .animation(.easeInOut, value: viewModel.text)
            Spacer()
        }
        .frame(maxWidth: .infinity)   // makes HStack expand horizontally
        .padding(0)
    }
}

final class ChatSystemMessageViewModel: ObservableObject {
    
    private let texts: [String]
    private var cancellables = Set<AnyCancellable>()
    private var index = 0
    @Published var text: String = ""
    
    init(texts: [String]) {
        self.texts = texts
        self.text = self.texts.first ?? ""
        if self.texts.count > 1 {
            index += 1
            Timer.publish(every: 2, on: RunLoop.main, in: .default)
                .autoconnect()
                .sink {[weak self] _ in
                    guard let self else {return}
                    if self.index >= self.texts.count {
                        self.index = 0
                    }
                    self.text = self.texts[self.index]
                    self.index += 1
                }.store(in: &cancellables)
                
        }
    }
}


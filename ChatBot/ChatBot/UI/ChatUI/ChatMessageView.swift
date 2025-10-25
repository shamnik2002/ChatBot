//
//  ChatView.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/17/25.
//

import Combine
import Foundation
import SwiftUI

struct ChatMessageView: View {
    
    struct Constants {
        static let topPadding: CGFloat = 10
        static let bottomPadding:CGFloat = 10
    }
    
    @ObservedObject var viewModel: ChatMessageViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 10){
            VStack(alignment: .leading) {
                Text(viewModel.chatDataModel.text)
                    .font(.headline)
                    .foregroundColor(viewModel.textColor)
                    .background(viewModel.backgroundColor)
                    .multilineTextAlignment(viewModel.textAlignment)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)   // makes HStack expand horizontally
        .padding(10)
        .cornerRadius(10)
    }
}

final class ChatMessageViewModel: ObservableObject {
    
    @Published var chatDataModel: ChatDataModel
    var backgroundColor: Color {
        switch chatDataModel.type {
            case .assistant:
                return Color(.systemGray6)
            case .user:
                return Color(.blue)
            case .system:
                return Color(.systemGray6)
        }
    }
    
    var textColor: Color {
        switch chatDataModel.type {
            case .assistant:
                return Color(.black)
            case .user:
                return Color(.white)
            case .system:
                return Color(.black)
        }
    }
    
    var textAlignment: TextAlignment {
        switch chatDataModel.type {
            case .assistant:
            return .leading
            case .user:
            return .trailing
            case .system:
            return .center
        }
    }
    init(chatDataModel: ChatDataModel) {
        self.chatDataModel = chatDataModel
    }
}


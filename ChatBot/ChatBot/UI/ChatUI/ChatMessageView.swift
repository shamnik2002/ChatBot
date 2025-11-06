//
//  ChatView.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/17/25.
//

import Combine
import Foundation
import SwiftUI

/// ChatMessageView
/// Displays the user input and response in chat view
struct ChatMessageView: View {
    
    struct Constants {
        static let topPadding: CGFloat = 10
        static let bottomPadding:CGFloat = 10
    }
    
    @ObservedObject var viewModel: ChatMessageViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 10){
            // based on whether it is user input or assisstant response we add spacing
            if viewModel.chatDataModel.type == .user {
                Spacer()
            }
            VStack(alignment: .trailing) {
                Text(viewModel.chatDataModel.text)
                    .font(.headline)
                    .foregroundColor(viewModel.textColor)
                    
                if viewModel.chatDataModel.type == .assistant {
                    Text(viewModel.chatDataModel.modelId)
                        
                        .font(.footnote)
                        .foregroundColor(viewModel.textColor)
                }
            }.padding(10)
             .background(viewModel.backgroundColor)
             .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)   // makes HStack expand horizontally
    }
}

/// ChatMessageViewModel
/// Provides appropriate UI data based on whether it is user input or assisstant response
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
    var alignment: HorizontalAlignment {
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


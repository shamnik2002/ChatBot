//
//  Untitled.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/7/25.
//

import SwiftUI
import Combine
import Foundation
import Charts

final class ChartsViewModel: ObservableObject, Identifiable {
    
    @Published var chatUsageData = [UsageDataModel]()
    @Published var conversationUsageData = [UsageDataModel]()
    @Published var dateUsageData = [UsageDataModel]()
    private var appStore: AppStore
    private var chatDataModel: ChatDataModel?
    
    init(appStore: AppStore, chatDataModel: ChatDataModel? = nil) {
        self.appStore = appStore
        self.chatUsageData = mockUsageDataModel()
        self.conversationUsageData = mockConvoUsageDataModel()
        self.dateUsageData = mockDateUsageDataModel()
    }
}

struct ChartsView: View {
    @StateObject var viewModel: ChartsViewModel
    
    var body: some View {
        NavigationView {
            VStack{
                Chart {
                    ForEach(viewModel.chatUsageData, id: \.id) { data in
                        BarMark (
                            x: .value("type", "Input"),
                            y: .value("tokens", data.inputTokens)
                        )
                        BarMark (
                            x: .value("type", "Output"),
                            y: .value("tokens", data.outputTokens)
                        )
                    }
                }.frame(maxHeight: 200)
                Text("Usage by chat")
                    .padding(10)
                Chart {
                    ForEach(viewModel.conversationUsageData, id: \.id) { data in
                        BarMark (
                            x: .value("type", "Input \(data.chatMessageID)"),
                            y: .value("tokens", data.inputTokens)
                        )
                        BarMark (
                            x: .value("type", "Output \(data.chatMessageID)"),
                            y: .value("tokens", data.outputTokens)
                        )
                    }
                }.frame(maxHeight: 200)
                Text("Usage by conversation")
                    .padding(10)
                Chart {
                    ForEach(viewModel.dateUsageData, id: \.id) { data in
                        BarMark (
                            x: .value("type", "Input \(data.chatMessageID)"),
                            y: .value("tokens", data.inputTokens)
                        )
                        BarMark (
                            x: .value("type", "Output \(data.chatMessageID)"),
                            y: .value("tokens", data.outputTokens)
                        )
                    }
                }.frame(maxHeight: 200)
                Text("Usage by date")
                    .padding(10)
            }
            .navigationTitle("Usage Charts")
                .navigationBarTitleDisplayMode(.inline)
        }
        
    }
}

func mockUsageDataModel() -> [UsageDataModel] {
    var data = [UsageDataModel]()
    
    data.append(UsageDataModel(id: UUID().uuidString, conversationID: "conversationID_1", chatMessageID: "chatMessageID_1", modelId: "gpt 5", modelProviderId: "Open AI", inputTokens: 5, outputTokens: 20, date: Date().timeIntervalSince1970, duration: 5))
    return data
}

func mockConvoUsageDataModel() -> [UsageDataModel] {
    var data = [UsageDataModel]()
    
    for i in 0..<5 {
        data.append(UsageDataModel(id: UUID().uuidString, conversationID: "conversationID_\(i)", chatMessageID: "chatMessageID_\(i)", modelId: "gpt 5", modelProviderId: "Open AI", inputTokens: 5, outputTokens: 20, date: Date().timeIntervalSince1970, duration: 5))
    }
    
    return data
}

func mockDateUsageDataModel() -> [UsageDataModel] {
    var data = [UsageDataModel]()
    
    for i in 0..<10 {
        data.append(UsageDataModel(id: UUID().uuidString, conversationID: "conversationID_\(i)", chatMessageID: "chatMessageID_\(i)", modelId: "gpt 5", modelProviderId: "Open AI", inputTokens: 5, outputTokens: 20, date: Date().timeIntervalSince1970, duration: 5))
    }
    
    return data
}

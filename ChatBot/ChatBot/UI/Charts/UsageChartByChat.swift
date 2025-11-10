//
//  UsageChartByChat.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/10/25.
//
import Combine
import Foundation
import SwiftUI
import Charts

final class UsageChartByChatViewModel: ObservableObject {
    @Published var usageData: [UsageDataModel] = []
    @Published var inputTotalString:String = ""
    @Published var outputTotalString:String = ""
    private var appStore: AppStore
    private var chatDataModel: ChatDataModel?
    private var cancellables = Set<AnyCancellable>()
    
    init(appStore: AppStore, chatDataModel: ChatDataModel? = nil) {
        self.appStore = appStore
        self.chatDataModel = chatDataModel
        appStore.usageState.usagePublisher
            .receive(on: RunLoop.main)
            .sink {[weak self] (action, data) in
                switch action {
                    case _ as GetUsageByChat:
                        self?.usageData = data
                        self?.calculateTotals()

                    default:
                        break
                }
            }.store(in: &cancellables)
        fetchUsageDataByChat()
        /*
         for testing
         self.usageData = mockUsageDataModel()
         */
    }
    
    func calculateTotals() {
        let (input, output) = usageData.calculateTotals()
        inputTotalString = "\(input.formatted(.number))"
        outputTotalString = "\(output.formatted(.number))"
    }
    
    func fetchUsageDataByChat() {
        guard let chatDataModel else { return }
        let action = GetUsageByChat(chatMessageId: chatDataModel.id, conversationId: chatDataModel.conversationID)
        appStore.dispacther.dispatch(action)
    }
}

struct UsagePieChart: View {
    @ObservedObject var viewModel: UsageChartByChatViewModel

    var body: some View {
        Chart(viewModel.usageData, id: \.id) { item in
          SectorMark(
            angle: .value("input", item.inputTokens),
            innerRadius: .ratio(0.6),
            angularInset: 2
          ).foregroundStyle(.blue)
          SectorMark(
            angle: .value("output", item.outputTokens),
            innerRadius: .ratio(0.6),
            angularInset: 2
          ).foregroundStyle(.green)
        }.chartForegroundStyleScale([
            "input \(viewModel.inputTotalString)": Color.blue,
            "output \(viewModel.outputTotalString)": Color.green
        ])
    }
}

fileprivate func mockUsageDataModel() -> [UsageDataModel] {
    var data = [UsageDataModel]()
    
    data.append(UsageDataModel(id: UUID().uuidString, conversationID: "conversationID_1", chatMessageID: "chatMessageID_1", modelId: "gpt 5", modelProviderId: "Open AI", inputTokens: 5, outputTokens: 20, date: Date().timeIntervalSince1970, duration: 5))
    return data
}

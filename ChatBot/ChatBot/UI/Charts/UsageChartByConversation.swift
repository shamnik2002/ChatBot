//
//  UsageChartByConversation.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/10/25.
//
import Combine
import Foundation
import SwiftUI
import Charts

final class UsageChartByConversationViewModel: ObservableObject {
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
                guard let self, let chatDataModel else {return}
                switch action {
                case let action as GetUsageByConversation where chatDataModel.conversationID == action.conversationId:
                        self.usageData = data

                    default:
                        break
                }
            }.store(in: &cancellables)
        
        appStore.usageState.usageTotalsPublisher
            .receive(on: RunLoop.main)
            .sink {[weak self] usageTotals in
                guard let self, let chatDataModel else {return}
                switch usageTotals.type {
                case let .conversation(conversationID: conversationID) where chatDataModel.conversationID == conversationID:
                        self.inputTotalString = "\(usageTotals.inputTokensTotal.formatted(.number))"
                        self.outputTotalString = "\(usageTotals.outputTokensTotal.formatted(.number))"
                    default:
                        break
                }
            }.store(in: &cancellables)
        fetchUsageDataByConversation()
        fetchUsageTotals()
        /*
         // For testing
        self.usageData = mockConvoUsageDataModel()
         */
    }
    
    func fetchUsageTotals() {
        guard let chatDataModel else {return}
        let action = GetUsageTotal(type: UsageTotalsType.conversation(conversationID: chatDataModel.conversationID))
        appStore.dispacther.dispatch(action)
    }
    
    func fetchUsageDataByConversation() {
        guard let chatDataModel else { return }
        let action = GetUsageByConversation(conversationId: chatDataModel.conversationID, pageLimit: 50, pageOffset: 0)
        appStore.dispacther.dispatch(action)
    }
}

struct UsageBarChart: View {
    @ObservedObject var viewModel: UsageChartByConversationViewModel
    
    var body: some View {
        Chart {
            ForEach(viewModel.usageData, id: \.id) {data in
                // 2 bar marks since we have 2 types of data we want to show per chat
                BarMark (
                    x: .value("input", data.chatMessageID),
                    y: .value("tokens", data.inputTokens)
                ).foregroundStyle(.blue)
                BarMark (
                    x: .value("output", data.chatMessageID),
                    y: .value("tokens", data.outputTokens)
                ).foregroundStyle(.green)
            }
        }.chartXAxisLabel("Chats")
        .chartYAxisLabel("tokens")
        .chartXAxis{
            axisMarksForChat()
        }
        .chartForegroundStyleScale([
                "input \(viewModel.inputTotalString)": Color.blue,
                "output \(viewModel.outputTotalString)": Color.green
            ])
    }
    func axisMarksForChat() -> some AxisContent {
            AxisMarks {
                AxisGridLine() // Add grid lines
                AxisTick() // Add ticks
                AxisValueLabel{
                    Text("") //TODO: show index of chat
                }
            }
        
    }
}

fileprivate func mockConvoUsageDataModel() -> [UsageDataModel] {
    var data = [UsageDataModel]()
    var date = Calendar.current.startOfDay(for: Date().dayBefore)

    for i in 0..<50 {
        data.append(UsageDataModel(id: UUID().uuidString, conversationID: "conversationID_\(i)", chatMessageID: "chatMessageID_\(i)", modelId: "gpt 5", modelProviderId: "Open AI", inputTokens: (100...300).randomElement() ?? 5, outputTokens: (200...1000).randomElement() ?? 20, date: date.timeIntervalSince1970, duration: 5))
        date = date.addingTimeInterval(3600 * 12)
    }
    
    return data
}

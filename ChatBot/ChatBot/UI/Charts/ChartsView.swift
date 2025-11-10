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
    private var cancellables = Set<AnyCancellable>()
    
    init(appStore: AppStore, chatDataModel: ChatDataModel? = nil) {
        self.appStore = appStore
        self.chatDataModel = chatDataModel
        /*
         // For testing
        self.chatUsageData = mockUsageDataModel()
        self.conversationUsageData = mockConvoUsageDataModel()
        self.dateUsageData = mockDateUsageDataModel()
         */
        appStore.usageState.usagePublisher
            .receive(on: RunLoop.main)
            .sink {[weak self] (action, data) in
                switch action {
                    case _ as GetUsageByChat:
                        self?.chatUsageData = data
                    case _ as GetUsageByConversation:
                        self?.conversationUsageData = data
                    case _ as GetUsageByDate:
                        self?.dateUsageData = data
                    default:
                        break
                }
            }.store(in: &cancellables)
        fetchUsageDataByChat()
        fetchUsageDataByConversation()
        fetchUsageDataByDate()
    }
    
    func fetchUsageDataByChat() {
        guard let chatDataModel else { return }
        let action = GetUsageByChat(chatMessageId: chatDataModel.id, conversationId: chatDataModel.conversationID)
        appStore.dispacther.dispatch(action)
    }
    
    func fetchUsageDataByConversation() {
        guard let chatDataModel else { return }
        let action = GetUsageByConversation(conversationId: chatDataModel.conversationID)
        appStore.dispacther.dispatch(action)
    }
    
    func fetchUsageDataByDate() {
        guard let chatDataModel else { return }
        let action = GetUsageByDate(date: chatDataModel.date)
        appStore.dispacther.dispatch(action)
    }
}

struct ChartsView: View {
    @ObservedObject var viewModel: ChartsViewModel
    var chartPadding = EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
    var chartTitlePadding = EdgeInsets(top: 0, leading: 10, bottom: 5, trailing: 10)
    var body: some View {
        NavigationView {
            ScrollView{

                UsagePieChart(viewModel: UsageChartViewModel(usageData: viewModel.chatUsageData))
                    .frame(minHeight: 150)
                    .padding(chartPadding)
                Text("Usage by chat")
                    .padding(chartTitlePadding)

                UsageBarChart(viewModel: UsageChartViewModel(usageData: viewModel.conversationUsageData))
                    .frame(minHeight: 200)
                    .padding(chartPadding)
                Text("Usage by conversation")
                    .padding(chartTitlePadding)

                UsageLineChart(viewModel: UsageChartViewModel(usageData: viewModel.dateUsageData))
                    .frame(minHeight: 200)
                    .padding(chartPadding)
                Text("Usage by date")
                    .padding(chartTitlePadding)
            }
            .navigationTitle("Usage Charts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

final class UsageChartViewModel: ObservableObject {
    @Published var usageData: [UsageDataModel]
    @Published var inputTotalString:String = ""
    @Published var outputTotalString:String = ""
    init(usageData: [UsageDataModel]) {
        self.usageData = usageData
        calculateTotals()
    }
    
    func calculateTotals() {
        let (input, output) = usageData.calculateTotals()
        inputTotalString = "\(input.formatted(.number))"
        outputTotalString = "\(output.formatted(.number))"
    }
}

struct UsageLineChart: View {
    @ObservedObject var viewModel: UsageChartViewModel
    
    var body: some View {
        Chart {
            ForEach(viewModel.usageData, id: \.id) { data in
                LineMark (
                    x: .value("date",  Date(timeIntervalSince1970: data.date)),
                    y: .value("input", data.inputTokens),
                    series: .value("input", "InputTokens")
                ).foregroundStyle(.blue)
                    .symbol{
                        Circle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: 8)
                    }
                                    
                LineMark (
                    x: .value("date", Date(timeIntervalSince1970: data.date)),
                    y: .value("output", data.outputTokens),
                    series: .value("output", "OutputTokens")
                ).foregroundStyle(.green)
                    .symbol{
                        Circle()
                            .fill(Color.green.opacity(0.6))
                            .frame(width: 8)
                    }
            }
        }.chartXAxisLabel("date")
        .chartYAxisLabel("tokens")
        .chartXAxis {
                axisMarksForDate()
            }
        .chartForegroundStyleScale([
                "input \(viewModel.inputTotalString)": Color.blue,
                "output \(viewModel.outputTotalString)": Color.green
            ])
    }
    
    // show specific labels on x axis
    // start with 12 AM and show marks at every 3 hours
    // only show AM/PM at midnight and noon
    func axisMarksForDate() -> some AxisContent {
         AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                if let date = value.as(Date.self) {
                    let hour = Calendar.current.component(.hour, from: date)
                    switch hour {
                    case 0, 12:
                        AxisValueLabel(format: .dateTime.hour())
                    default:
                        AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                    }
                }
                
                AxisGridLine()
                AxisTick()
         }
    }
}

struct UsageBarChart: View {
    @ObservedObject var viewModel: UsageChartViewModel
    
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

struct UsagePieChart: View {
    @ObservedObject var viewModel: UsageChartViewModel

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

extension Array where Element == UsageDataModel {
    
    func calculateTotals() -> (Int, Int){
        var input = 0
        var output = 0
        self.forEach { data in
            input += data.inputTokens
            output += data.outputTokens
        }
        return (input, output)
    }
}

func mockUsageDataModel() -> [UsageDataModel] {
    var data = [UsageDataModel]()
    
    data.append(UsageDataModel(id: UUID().uuidString, conversationID: "conversationID_1", chatMessageID: "chatMessageID_1", modelId: "gpt 5", modelProviderId: "Open AI", inputTokens: 5, outputTokens: 20, date: Date().timeIntervalSince1970, duration: 5))
    return data
}

func mockConvoUsageDataModel() -> [UsageDataModel] {
    var data = [UsageDataModel]()
    var date = Calendar.current.startOfDay(for: Date().dayBefore)

    for i in 0..<50 {
        data.append(UsageDataModel(id: UUID().uuidString, conversationID: "conversationID_\(i)", chatMessageID: "chatMessageID_\(i)", modelId: "gpt 5", modelProviderId: "Open AI", inputTokens: (100...300).randomElement() ?? 5, outputTokens: (200...1000).randomElement() ?? 20, date: date.timeIntervalSince1970, duration: 5))
        date = date.addingTimeInterval(3600 * 12)
    }
    
    return data
}

func mockDateUsageDataModel() -> [UsageDataModel] {
    var data = [UsageDataModel]()
    
    var date = Calendar.current.startOfDay(for: Date())
    
    for i in 0..<100 {
        if !Calendar.current.isDateInToday(date) {
            break
        }
        data.append(UsageDataModel(id: UUID().uuidString, conversationID: "conversationID_\(i)", chatMessageID: "chatMessageID_\(i)", modelId: "gpt 5", modelProviderId: "Open AI", inputTokens: (100...300).randomElement() ?? 5, outputTokens: (200...1000).randomElement() ?? 20, date: date.timeIntervalSince1970, duration: 5))
        date = date.addingTimeInterval(3600)
    }
    
    return data
}

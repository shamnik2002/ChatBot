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

                UsageBarChart(usageData: viewModel.chatUsageData)
                    .frame(maxHeight: 200)
                    .padding(10)
                Text("Usage by chat")
                    .padding(10)
                
                UsageBarChart(usageData: viewModel.conversationUsageData)
                    .frame(maxHeight: 200)
                    .padding(10)
                Text("Usage by conversation")
                    .padding(10)
                
                UsageLineChart(usageData: viewModel.dateUsageData)
                    .frame(maxHeight: 250)
                    .padding(10)
                Text("Usage by date")
                    .padding(10)
            }
            .navigationTitle("Usage Charts")
                .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    
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

struct UsageLineChart: View {
    var usageData: [UsageDataModel]
    var inputTotal = 5000
    var outputTotal = 8600
    var body: some View {
        Chart {
            ForEach(usageData, id: \.id) { data in
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
                "input \(inputTotal)": Color.blue,
                "output \(outputTotal)": Color.green
            ])
    }
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
    var usageData: [UsageDataModel]
    
    var body: some View {
        Chart {
            ForEach(usageData, id: \.id) {data in
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

extension AxisContent {
    func axisMarksForDate() -> some AxisContent {
         AxisMarks(values: .stride(by: .hour, count: 12)) { value in
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

func mockUsageDataModel() -> [UsageDataModel] {
    var data = [UsageDataModel]()
    
    data.append(UsageDataModel(id: UUID().uuidString, conversationID: "conversationID_1", chatMessageID: "chatMessageID_1", modelId: "gpt 5", modelProviderId: "Open AI", inputTokens: 5, outputTokens: 20, date: Date().timeIntervalSince1970, duration: 5))
    return data
}

func mockConvoUsageDataModel() -> [UsageDataModel] {
    var data = [UsageDataModel]()
    var date = Calendar.current.startOfDay(for: Date().dayBefore)

    for i in 0..<100 {
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

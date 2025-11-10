//
//  UsageChartByDate.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/10/25.
//

import Combine
import Foundation
import SwiftUI
import Charts

final class UsageChartByDateViewModel: ObservableObject {
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
                    case _ as GetUsageByDate:
                        self?.usageData = data
                        self?.calculateTotals()

                    default:
                        break
                }
            }.store(in: &cancellables)
        fetchUsageDataByDate()
        /*
         // For testing
         self.usageData = mockDateUsageDataModel()
         */
    }
    
    func calculateTotals() {
        let (input, output) = usageData.calculateTotals()
        inputTotalString = "\(input.formatted(.number))"
        outputTotalString = "\(output.formatted(.number))"
    }
    
    func fetchUsageDataByDate() {
        guard let chatDataModel else { return }
        let action = GetUsageByDate(date: chatDataModel.date)
        appStore.dispacther.dispatch(action)
    }
}

struct UsageLineChart: View {
    @ObservedObject var viewModel: UsageChartByDateViewModel
    
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

fileprivate func mockDateUsageDataModel() -> [UsageDataModel] {
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

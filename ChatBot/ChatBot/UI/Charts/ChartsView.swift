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
    
    var appStore: AppStore
    var chatDataModel: ChatDataModel?
    
    init(appStore: AppStore, chatDataModel: ChatDataModel? = nil) {
        self.appStore = appStore
        self.chatDataModel = chatDataModel        
    }
}

struct ChartsView: View {
    @ObservedObject var viewModel: ChartsViewModel
    var chartPadding = EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
    var chartTitlePadding = EdgeInsets(top: 0, leading: 10, bottom: 5, trailing: 10)
    var body: some View {
        NavigationView {
            ScrollView{

                UsagePieChart(viewModel: UsageChartByChatViewModel(appStore: viewModel.appStore, chatDataModel: viewModel.chatDataModel))
                    .frame(minHeight: 150)
                    .padding(chartPadding)
                Text("Usage by chat")
                    .padding(chartTitlePadding)

                UsageBarChart(viewModel: UsageChartByConversationViewModel(appStore: viewModel.appStore, chatDataModel: viewModel.chatDataModel))
                    .frame(minHeight: 200)
                    .padding(chartPadding)
                Text("Usage by conversation")
                    .padding(chartTitlePadding)

                UsageLineChart(viewModel: UsageChartByDateViewModel(appStore: viewModel.appStore, chatDataModel: viewModel.chatDataModel))
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


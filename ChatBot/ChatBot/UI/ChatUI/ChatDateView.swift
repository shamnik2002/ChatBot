//
//  ChatDateView.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/18/25.
//

import Combine
import Foundation
import SwiftUI

///ChatDateView
///Displays the date in chat view
struct ChatDateView: View {
    
    struct Constants {
        static let topPadding: CGFloat = 10
        static let bottomPadding:CGFloat = 5
    }
    
    @ObservedObject var viewModel: ChatDateViewModel
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0){
            Spacer()
            Text(viewModel.date)
                .foregroundColor(Color(.lightGray))
            Spacer()
        }
        .frame(maxWidth: .infinity)   // makes HStack expand horizontally
        .padding(0)
    }
}

final class ChatDateViewModel: ObservableObject {
    
    private let dateDataModel: DateDataModel
    
    var date: String {
        return Date(timeIntervalSince1970: dateDataModel.date).shortRelativeDate()
    }
    
    init(dateDataModel: DateDataModel) {
        self.dateDataModel = dateDataModel
    }
}


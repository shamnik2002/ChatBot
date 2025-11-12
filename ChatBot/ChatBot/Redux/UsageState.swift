//
//  UsageState.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/7/25.
//

import Combine
import Foundation

final class UsageState {
    private let dispatch: Dispatch
    let usagePublisher = PassthroughSubject<(UsageAction,[UsageDataModel]), Never>()
    let usageTotalsPublisher = PassthroughSubject<UsageTotals, Never>()

    private var cancellable = Set<AnyCancellable>()
    init(dispatch:@escaping Dispatch, listener: AnyPublisher<UsageMutatingAction?, Never>) {
        self.dispatch = dispatch
        
        listener.sink {[weak self] action in
            guard let action else {return}
            self?.handle(action: action)
        }.store(in: &cancellable)
    }
    
    private func handle(action: ReduxMutatingAction) {
        switch action {
            case let action as SetUsage:
                usagePublisher.send((action.originalAction, action.usageData))
                break
            case let action as SetUsageTotal:
                usageTotalsPublisher.send(action.usageTotal)
                break
            default:
                break
        }
    }
}

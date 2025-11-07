//
//  SettingsState.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/6/25.
//
import Combine

final class SettingsState {
    
    private let dispatch: Dispatch    
    private(set) var settingsPublisher = PassthroughSubject<Any?, Error>()
    private var cancellables = Set<AnyCancellable>()

    init(dispatch: @escaping Dispatch, listner: AnyPublisher<SettingsMutatingAction?, Never>) {
        self.dispatch = dispatch
        listner.sink {[weak self] action in
            guard let action else {return}
            self?.handle(action: action)
        }.store(in: &cancellables)
    }
    
    private func handle(action: ReduxAction) {
        switch action {
            case let action as SetSettingsObject:
                settingsPublisher.send(action.value)
            default:
                break
        }
    }
}

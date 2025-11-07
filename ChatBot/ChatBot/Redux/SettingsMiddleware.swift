//
//  SettingsMiddleware.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/6/25.
//

import Combine

final class SettingsMiddleware {
    
    private var cancellables = Set<AnyCancellable>()
    private let dispatch: Dispatch
    private var store: SettingsStore
    
    init(dispatch: @escaping Dispatch, store: SettingsStore, listner: AnyPublisher<SettingsAction?, Never>) {
        self.dispatch = dispatch
        self.store = store
        // Listner to Get conversation actions from dispatcher
        listner.sink {[weak self] action in
            guard let action = action else { return }
            self?.handle(action: action)
        }.store(in: &cancellables)
    }
    
    /// Handle actions
    private func handle(action: ReduxAction) {
        switch action {
            case let action as GetSettingsObject:
                fetchSettings(action: action)
            case let action as UpdateSettingsObject:
                updateSettings(action: action)
            default:
                break
        }
    }
    
    func fetchSettings(action: GetSettingsObject) {
        Task {
            let value = await store.getObject(action.key) as? Codable
            let action = SetSettingsObject(key: action.key, value: value, error: nil)
            dispatch(action)            
        }
    }
    
    func updateSettings(action: UpdateSettingsObject) {
        Task {
            do {
                try await store.setObject(action.value, key: action.key)
                let action = SetSettingsObject(key: action.key, value: action.value, error: nil)
                dispatch(action)
            }catch {
                let action = SetSettingsObject(key: action.key, value: nil, error: error)
                dispatch(action)
            }
        }
    }
}

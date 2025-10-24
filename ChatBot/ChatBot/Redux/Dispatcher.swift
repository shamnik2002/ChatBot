//
//  Dispatcher.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//
import Combine
import Foundation

typealias Dispatch = (ReduxAction) -> Void
final class Dispatcher {
    
    @Published var getChat: GetChat?
    @Published var setChat: SetChat?
    
    func dispatch(_ action: ReduxAction) {
        switch action {
            case let action as GetChat:
                self.getChat = action
            case let action as SetChat:
                self.setChat = action
            default:
                break
        }
    }
}

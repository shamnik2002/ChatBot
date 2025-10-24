//
//  Store.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//

import Foundation
import Combine

final class AppStore {
    
    let appState: AppState
    let appMiddleWare: AppMiddleware
    let dispacther: Dispatcher
    static let shared = AppStore()
    
    init() {
        self.dispacther = Dispatcher()
        self.appState = AppState(dispatch: self.dispacther.dispatch(_:), listner: self.dispacther.$setChat.eraseToAnyPublisher())
        self.appMiddleWare = AppMiddleware(dispatch: self.dispacther.dispatch(_:), networkService: NetworkService(), parser: Parser(), listner: self.dispacther.$getChat.eraseToAnyPublisher())
    }
}


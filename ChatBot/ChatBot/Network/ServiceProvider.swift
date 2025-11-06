//
//  ServiceProvider.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/5/25.
//

import Foundation

struct ServiceProvider {
    
    private var providers: [String: ServiceProtocol]
    private var networkService: NetworkProtocol
    private var parser: ParseProtocol
    init(networkService: NetworkProtocol, parser: ParseProtocol) {
        self.networkService = networkService
        self.parser = parser
        providers = [OpenAIProvider.id: OpenAIService(parser: parser, networkService: networkService)]
    }
    
    func provider(id: String) -> ServiceProtocol? {
        return providers[id]
    }
}

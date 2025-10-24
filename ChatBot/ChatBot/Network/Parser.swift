//
//  Parser.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//
import Foundation
import Combine

protocol ParseProtocol {
    func parse<T: Codable>(data: Data, type: T.Type) -> AnyPublisher<T, Error>
}

struct Parser: ParseProtocol {
    func parse<T: Codable>(data: Data, type: T.Type) -> AnyPublisher<T, Error> {
        
        return Just(data)
            .tryMap{ data in
                do {
                    let result = try JSONDecoder().decode(T.self, from: data)
                    return result
                } catch {
                    // log error
                    throw error
                }
            }.eraseToAnyPublisher()
    }
}

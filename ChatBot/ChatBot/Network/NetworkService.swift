//
//  NetworkService.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//

import Foundation
import Combine

protocol NetworkProtocol {
    func fetchDataWithPublisher(request: RequestProtocol) -> AnyPublisher<Data, Error>
}

struct NetworkService: NetworkProtocol {
    
    let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchDataWithPublisher(request: RequestProtocol) -> AnyPublisher<Data, Error> {
        guard let urlRequest = try? request.buildRequest() else {
            return Fail(error: NetworkError.invalidRequest).eraseToAnyPublisher()
        }
        return session.dataTaskPublisher(for: urlRequest)
            .tryMap{ response in
                
                guard let httpResponse = response.response as? HTTPURLResponse else {
                    throw NetworkError.unknownError
                }
                
                switch httpResponse.statusCode {
                    case 200...299:
                        return response.data
                    case 401:
                        throw NetworkError.authError
                    case 403:
                        throw NetworkError.forbiddenError
                    case 500...599:
                        throw NetworkError.serverError
                    default:
                        throw NetworkError.unknownError
                }
            }.eraseToAnyPublisher()
    }
}

enum NetworkError: Error {
    case invalidRequest
    case authError
    case forbiddenError
    case serverError
    case unknownError
}

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
    func fetchData(request: RequestProtocol) async throws -> Data
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
                
                // Map to our error enum
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
    
    func fetchData(request: RequestProtocol) async throws -> Data {
        guard let urlRequest = try? request.buildRequest() else {
            throw NetworkError.invalidRequest
        }
        let response = try await session.data(for: urlRequest)
        guard let httpResponse = response.1 as? HTTPURLResponse else {
            throw NetworkError.unknownError
        }
        
        // Map to our error enum
        switch httpResponse.statusCode {
            case 200...299:
                return response.0
            case 401:
                throw NetworkError.authError
            case 403:
                throw NetworkError.forbiddenError
            case 500...599:
                throw NetworkError.serverError
            default:
                throw NetworkError.unknownError
        }
    }
}

enum NetworkError: Error {
    case invalidRequest
    case authError
    case forbiddenError
    case serverError
    case unknownError
}

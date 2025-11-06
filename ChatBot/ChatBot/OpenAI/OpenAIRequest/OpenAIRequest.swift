//
//  OpenAIRequest.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/16/25.
//

import Foundation

struct ResponsesRequest: RequestProtocol {
    var scheme: Scheme = .https
    
    var httpMethod: HttpMethod = .post
    
    var host: String = OpenAIContants.host
    
    var path: String = "/v1/responses"
    
    var headers: [String : String] = OpenAIContants.headers
    
    var queryParams: [String : String]?
    
    var bodyParams: [String : String]?
    
    var body: Data?
    
    func buildRequest() throws -> URLRequest {
        var components = URLComponents()
        components.scheme = scheme.rawValue
        components.host = host
        components.path = path
        if let queryParams {
            components.queryItems = queryParams.map{URLQueryItem(name: $0.key, value: $0.value)}
        }        
        guard let url = components.url  else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.allHTTPHeaderFields = headers
        if let bodyParams {
            if let data = try? JSONSerialization.data(withJSONObject: bodyParams) {
                urlRequest.httpBody = data
            }
        }
        return urlRequest
    }
    
    /// Accepts input text and previous responseId
    init(input: String, responseId: String?, model: String) {
        //TODO: add some validation here, perhaps accept model
        var params = [OpenAIContants.modelKey: model, OpenAIContants.inputKey: input]
        if let responseId {
            params[OpenAIContants.previousResponseIdKey] = responseId
        }
        self.bodyParams = params
    }
}

//
//  Request.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//

import Foundation

protocol RequestProtocol {
    var scheme: Scheme { get }
    var httpMethod: HttpMethod { get }
    var host: String { get }
    var path: String { get }
    var headers: [String: String] { get }
    var queryParams: [String: String]? { get }
    var body: Data? { get }
    
    func buildRequest() throws -> URLRequest
}

enum Scheme: String {
    case https
}

enum HttpMethod: String {
    case get
    case post
}

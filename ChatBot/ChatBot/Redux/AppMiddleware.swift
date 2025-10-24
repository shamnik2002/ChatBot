//
//  AppMiddleware.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//

import Foundation
import Combine

var mockDate = Date()
final class AppMiddleware {
    
    private let networkService: NetworkProtocol
    private let parser: ParseProtocol
    private var cancellables = Set<AnyCancellable>()
    private let dispatch: Dispatch
    
    init(dispatch: @escaping Dispatch, networkService: NetworkProtocol, parser: ParseProtocol, listner: AnyPublisher<GetChat?, Never>) {
        self.dispatch = dispatch
        self.networkService = networkService
        self.parser = parser
        
        listner.sink {[weak self] action in
            guard let action = action else { return }
            self?.handle(action: action)
        }.store(in: &cancellables)
    }
    
    func handle(action: ReduxAction) {
        switch action {
            case let action as GetChatResponse:
                addUserMessage(input: action.input)
                fetchMockResponse()
//                fetchResponses(input: action.input)
                break
        case let action as GetOldChatResponses:
            fetchMockResponses()
            default:
                break
        }
    }
    
    func fetchResponses(input: String) {
        let request = ResponsesRequest(input: input)
        let parser = parser
        let dispatch = dispatch
        networkService.fetchDataWithPublisher(request: request)
            .flatMap { data in
                return parser.parse(data: data, type: ChatResponse.self)
            }.sink { completion in
                
            } receiveValue: { result in
                let setChatResponse = SetChatResponse(response: result)
                dispatch(setChatResponse)
            }.store(in: &cancellables)
    }
    
    func addUserMessage(input: String) {
        let date = ceil(Date().timeIntervalSince1970)
        let userChat = ChatDataModel(id: UUID().uuidString, text: input, date: date, type: ChatResponseRole.user)
        let setUserChatMessageAction = SetUserChatMessage(chatDataModel: userChat)
        dispatch(setUserChatMessageAction)
    }
    
    func fetchMockResponses() {
        
        Task {[weak self] in
//            try? await Task.sleep(for: .seconds(1))
            let oldChats = randomStringGenerator(count: 20)
            var responses = [ChatResponse]()
            var delta:TimeInterval = 60*2
            for chat in oldChats {
                let content = ChatResponse.Output.Content(type: "output_text", text: chat)
                let output = ChatResponse.Output(type: "message", id: UUID().uuidString, role: ChatResponseRole.assistant.rawValue, content: [content])
                let response = ChatResponse(id: UUID().uuidString, created_at: mockDate.timeIntervalSince1970 - delta, output: [output])
                responses.append(response)
                delta -= 60*2
            }
            let setResponsesAction = SetOldChatResponses(responses: responses)
            self?.dispatch(setResponsesAction)
            mockDate = mockDate.dayBefore
        }
        
    }
    
    func fetchMockResponse() {
        Task {[weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let chatBotresponse = randomStringGenerator(count: 1).first else {return}
            let content = ChatResponse.Output.Content(type: "output_text", text: chatBotresponse)
            let output = ChatResponse.Output(type: "message", id: UUID().uuidString, role: ChatResponseRole.assistant.rawValue, content: [content])
            let response = ChatResponse(id: UUID().uuidString, created_at: Date().timeIntervalSince1970, output: [output])
            let setResponsesAction = SetChatResponse(response: response)
            self?.dispatch(setResponsesAction)
        }
    }
}

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}

func randomStringGenerator(count: Int) -> [String] {
    var strings = [String]()
    let letters = " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    for _ in 0..<count {
        let length = (500...1000).randomElement() ?? 5
        let str = String((0..<length).map{ _ in letters.randomElement()! })
        strings.append(str)
    }
    return strings
}

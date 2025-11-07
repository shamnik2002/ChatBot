//
//  SettingsStore.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/6/25.
//
import Foundation

enum SettingsStoreError: Error {
    case invalidType
}

actor SettingsStore {
    
    struct Constants {
        static let currentModelKey = "currentModel"
    }
    
    private var _currentModel: ProviderModel?
    
    private func validate(value: Any, key: String) -> Bool  {
        switch key {
        case Constants.currentModelKey:
            return value is ProviderModel?
        default:
            return false
        }
    }
    
    private func defaultValue(key: String) -> Any? {
        switch key {
        case Constants.currentModelKey:
            return OpenAIProvider.model(.gpt_5_nano)
        default:
            return nil
        }
    }
    
    private func valueType(key: String) -> Codable.Type? {
        switch key {
        case Constants.currentModelKey:
            return ProviderModel.self
        default:
            return nil
        }
    }
    
    //TODO: add validation
    func getObject(_ key: String) -> Any? {
        
        if let data = UserDefaults.standard.data(forKey: key),
           let type = valueType(key: key),
           let value = try? JSONDecoder().decode(type, from: data) {
            
            return value
        }
        return defaultValue(key: key)
    }
    
    func setObject(_ object: Codable, key: String) throws {
        guard validate(value: object, key: key) else {
            throw SettingsStoreError.invalidType
        }
        let encodedData = try JSONEncoder().encode(object)
        UserDefaults.standard.set(encodedData, forKey: key)
    }
}

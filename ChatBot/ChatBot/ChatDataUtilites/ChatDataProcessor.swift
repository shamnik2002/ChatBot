//
//  ChatDataProcessor.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/18/25.
//
import Foundation
import Combine

/// Data Processor
/// Tranforms input data by making necessary changes like adds, edits, removes
protocol DataProcessor<InputDataType, OutputDataType> {
    associatedtype InputDataType: Hashable
    associatedtype OutputDataType: Hashable
    func process(data: InputDataType, lookupData:OutputDataType?) -> OutputDataType
}

/// ChatDataProcessor
/// Accepts ChatDataModel and returns the data that can be displayed in the ChatCollectionView
/// Adds the necessary date sections by processing data and dedupes based on lookupData
final class ChatDataProcessor: DataProcessor {
    typealias InputDataType = [ChatDataModel]
    typealias OutputDataType = [ChatCollectionViewDataItem]
    
    func process(data: [ChatDataModel], lookupData:[ChatCollectionViewDataItem]? = nil) -> [ChatCollectionViewDataItem] {
        var dataModels = [ChatCollectionViewDataItem]()
                
        var date: String = ""
        if let lookupData = lookupData as? [DateDataModel] {
            if let lookUpDate = lookupData.first?.date{
                date = Date(timeIntervalSince1970: lookUpDate).shortRelativeDate()
            }
        }
        for item in data {
            let itemDate = Date(timeIntervalSince1970: item.date).shortRelativeDate()
            if date != itemDate {
                let dateDataModel = DateDataModel(id: UUID().uuidString, date: item.date)
                dataModels.append(dateDataModel)
            }
            date = itemDate
            dataModels.append(item)
        }
        return dataModels
    }
}

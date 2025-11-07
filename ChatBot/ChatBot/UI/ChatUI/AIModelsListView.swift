//
//  AIModelsListView.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/6/25.
//
import SwiftUI
import Combine

final class AIModelsListViewModel: ObservableObject {
        
    @Published var currentModel: ProviderModel?
    private var appStore: AppStore
    private var cancellables = Set<AnyCancellable>()
    
    init(appStore: AppStore) {
        self.appStore = appStore
        self.appStore.settingsState.settingsPublisher
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in
                
            }, receiveValue: {[weak self] value in
                guard let model = value as? ProviderModel else {
                    return
                }
                self?.currentModel = model
            })
            .store(in: &cancellables)
        getCurrentModel()
    }
    
    func getCurrentModel() {
        let action = GetSettingsObject(key: SettingsStore.Constants.currentModelKey)
        appStore.dispacther.dispatch(action)
    }
    
    func models() -> [ProviderModel] {
        OpenAIProvider.models()
    }
    
    func selectModel(_ model: ProviderModel) {
        let action = UpdateSettingsObject(key: SettingsStore.Constants.currentModelKey, value: model)
        appStore.dispacther.dispatch(action)
    }
}

struct AIModelsListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AIModelsListViewModel
    
    var body: some View {
        NavigationView{
            List {
                ForEach(viewModel.models(), id: \.hashValue) { item in
                    Button{
                        viewModel.selectModel(item)
                        dismiss()
                    }label: {
                        HStack {
                            Text(item.name)
                                .foregroundColor(.blue)
                            if let currentModel = viewModel.currentModel, item.hashValue == currentModel.hashValue {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }.listStyle(.inset)
            .navigationTitle("Models")
            .navigationBarTitleDisplayMode(.inline)            
        }
        .background(Color.clear)
    }
}

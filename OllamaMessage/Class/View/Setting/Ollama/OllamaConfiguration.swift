//
//  OllamaConfiguration.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/3/25.
//

import SwiftUI

struct HeaderItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var key: String
    var value: String
}


class OllamaConfiguration: ObservableObject, @unchecked Sendable {
    static let shared = OllamaConfiguration()
    
    @AppStorage("ollamaAPIHost") var apiHost: String = ""
    
    @AppStorage("ollama.options.temperature") var temperature: Double = 0.8
    @AppStorage("ollama.options.numCtx") var numCtx: Int = 2048
    @AppStorage("ollama.options.numKeep") var numKeep: Int = 5
    @AppStorage("ollama.keepAlive") var keepAlive: Int = 5 * 60

    
    @Published var models: [OllamaModel] = []
    @Published var version: String = ""
    
    @Published var isFetching = false
    
    @Published var error: Error?
    
    @MainActor
    func fetchModels() async {
        guard let url = URL(string: apiHost + "/api/tags") else {
            return
        }
        withAnimation {
            error = nil
            models = []
            isFetching = true
        }
        var request = URLRequest(url: url)
        for header in OllamaConfiguration.shared.headerItems {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let models = try decoder.decode(OllamaModelResponse.self, from: data).models.sorted {
                $0.name < $1.name
            }
            self.models = models
            if AppConfiguration.shared.model.isEmpty {
                AppConfiguration.shared.model = models.first?.name ?? ""
            }
            print(models)
        } catch {
            print(error)
            withAnimation {
                self.models = []
                self.error = error
            }
        }
        withAnimation {
            isFetching = false
        }
    }
    
    init() {
        headerItems = getHeaderItems()
    }
    
    @Published var headerItems: [HeaderItem] = [] {
        didSet {
            updateHeaderItems(headerItems)
        }
    }
    
    @AppStorage("ollama.headerItems") private var headerItemsJson: String = ""
    
    private func updateHeaderItems(_ items: [HeaderItem]) {
        if let encoded = try? JSONEncoder().encode(items),
           let jsonString = String(data: encoded, encoding: .utf8) {
            headerItemsJson = jsonString
        }
    }
    
    private func getHeaderItems() -> [HeaderItem] {
        guard let data = headerItemsJson.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([HeaderItem].self, from: data) else {
            return []
        }
        return decoded
    }
        
}


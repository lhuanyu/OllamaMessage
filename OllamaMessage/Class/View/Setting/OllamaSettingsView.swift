//
//  OllamaSettingsView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/2/14.
//

import Kingfisher
import SwiftUI

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
        let request = URLRequest(url: url)
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
}

struct OllamaSettingsView: View {
    @AppStorage("configuration.model") var modelName: String = ""
            
    @StateObject var configuration = OllamaConfiguration.shared
    
    @State var models = [OllamaModel]()
    
    @State var selectedModel: OllamaModel?
    
    @State private var showOllamaModelList = false
    
    var body: some View {
        List {
            Section("API") {
                TextField("API Host", text: $configuration.apiHost)
            }
            Section("Options") {
                Stepper(value: $configuration.temperature, in: 0...2, step: 0.1) {
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text(String(format: "%.1f", configuration.temperature))
                            .padding(.horizontal)
                            .height(32)
                            .width(60)
                            .background(Color.secondarySystemFill)
                            .cornerRadius(8)
                    }
                }
                Stepper(value: $configuration.numCtx, in: 512...20480, step: 512) {
                    HStack {
                        Text("Context Size")
                        Spacer()
                        Text(String(format: "%d", configuration.numCtx))
                            .padding(.horizontal)
                            .height(32)
                            .background(Color.secondarySystemFill)
                            .cornerRadius(8)
                    }
                }
                Stepper(value: $configuration.keepAlive, in: -1...3600, step: 30) {
                    HStack {
                        Text("Keep Alive")
                        Spacer()
                        Text(String(format: "%d s", configuration.keepAlive))
                            .padding(.horizontal)
                            .height(32)
                            .background(Color.secondarySystemFill)
                            .cornerRadius(8)
                    }
                }
            }
            Section {
                if isFetching {
                    HStack {
                        ProgressView()
                    }
                } else if let error = error {
                    Text("Failed to fetch models: \(error.localizedDescription)")
                        .foregroundColor(.red)
                } else {
                    ForEach(models) { model in
                        HStack {
                            KFImage.url(model.name.ollamaModelProvider.iconURL)
                                .resizable()
                                .frame(width: 24, height: 24)
                            Text(model.name + "(\(model.details.parameterSize))")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            #if targetEnvironment(macCatalyst)
                            UIApplication.shared.open(URL(string: "https://ollama.com/library/\(model.name)")!)
                            #else
                            selectedModel = model
                            #endif
                        }
                    }
                }
            } header: {
                Text("Models")
            } footer: {
                if isFetching {
                    Text("Fetching models...")
                        .font(.caption)
                } else {
                    Button {
                        #if targetEnvironment(macCatalyst)
                        UIApplication.shared.open(URL(string: "https://ollama.com/library")!)
                        #else
                        showOllamaModelList = true
                        #endif
                    } label: {
                        Text("See all models on Ollama")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .task {
            await fetchModels()
        }
        .onChange(of: configuration.apiHost) { _ in
            Task {
                await fetchModels()
            }
        }
        .navigationBarTitle("Ollama")
        .sheet(item: $selectedModel) { model in
            SafariView(url: URL(string: "https://ollama.com/library/\(model.name)")!)
        }
        .sheet(isPresented: $showOllamaModelList) {
            SafariView(url: URL(string: "https://ollama.com/library")!)
        }
    }
    
    @State private var isFetching = true
    
    @State private var error: Error?
    
    func fetchModels() async {
        guard let url = URL(string: configuration.apiHost + "/api/tags") else {
            return
        }
        withAnimation {
            error = nil
            models = []
            isFetching = true
        }
        let request = URLRequest(url: url)
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let models = try decoder.decode(OllamaModelResponse.self, from: data).models.sorted {
                $0.name < $1.name
            }
            withAnimation {
                self.models = models
                if modelName.isEmpty {
                    modelName = models.first?.name ?? ""
                }
                isFetching = false
            }
            print(models)
        } catch {
            withAnimation {
                self.error = error
                isFetching = false
            }
            print(error)
        }
    }
}

#Preview {
    NavigationView {
        OllamaSettingsView()
            .onAppear {
                UIPasteboard.general.string = "http://localhost:11434"
            }
    }
}

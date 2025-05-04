//
//  OllamaSettingsView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/2/14.
//

import Kingfisher
import SwiftUI

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
            Section(header: Text("Custom Headers")) {
                ForEach($configuration.headerItems) { $header in
                    VStack {
                        HStack {
                            Image(systemName: "k.circle.fill")
                            TextField("Key", text: $header.key)
                        }
                        .frame(height: 32)

                        HStack {
                            Image(systemName: "v.circle.fill")
                            TextField("Value", text: $header.value)
                        }
                        .frame(height: 32)
                    }
                }
                .onDelete { indexSet in
                    configuration.headerItems.remove(atOffsets: indexSet)
                }
                
                Button(action: addHeader) {
                    Label("Add Header", systemImage: "plus.circle.fill")
                }
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
                Stepper(value: $configuration.numCtx, in: 512...40960, step: 512) {
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
    
    private func addHeader() {
        withAnimation {
            configuration.headerItems.append(HeaderItem(key: "", value: ""))
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

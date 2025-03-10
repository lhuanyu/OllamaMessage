//
//  OllamaMessageApp.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/22.
//

import SwiftUI

@main
struct OllamaMessageApp: App {
    let persistenceController = PersistenceController.shared

    @State var showOllamaHostAlert = false
    
    @StateObject var appConfiguration = AppConfiguration.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if appConfiguration.ollamaAPIHost.isEmpty {
                        showOllamaHostAlert = true
                    }
                }
                .environmentObject(appConfiguration)
                .alert("Enter Ollama API Host", isPresented: $showOllamaHostAlert) {
                    TextField("Ollama API Host", text: appConfiguration.$ollamaAPIHost)
                    Button("Later", role: .cancel) {}
                    Button("Confirm", role: .none) {}
                } message: {
                    Text("You need set Ollama API host before start a conversation.")
                }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onChange(of: appConfiguration.ollamaAPIHost) { _ in
                    Task {
                        await OllamaConfiguration.shared.fetchModels()
                    }
                }
        }
    }
}

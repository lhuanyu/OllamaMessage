//
//  OllamaMessageApp.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/22.
//

import CoreSpotlight
import SwiftUI

@main
struct OllamaMessageApp: App {
    let persistenceController = PersistenceController.shared

    @State var showOllamaHostAlert = false

    @StateObject var appConfiguration = AppConfiguration.shared
    
    // 添加用于在App启动后打开特定会话的状态变量
    @State var spotlightSessionId: UUID?

    var body: some Scene {
        WindowGroup {
            ContentView(spotlightSessionId: $spotlightSessionId)
                .onAppear {
                    if appConfiguration.ollamaAPIHost.isEmpty {
                        showOllamaHostAlert = true
                    }

                    // Initialize app search indexing
                    AppSearchHandler.shared.indexAppContent()
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
                // 处理从Spotlight搜索打开应用的情况
                .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                    if let uniqueIdentifier = userActivity.userInfo?[
                        CSSearchableItemActivityIdentifier] as? String
                    {
                        print("Opening from search, search ID: \(uniqueIdentifier)")
                        
                        // 检查是否是会话类型的搜索结果
                        if uniqueIdentifier.hasPrefix("session-") {
                            // 提取会话的UUID
                            let uuidString = uniqueIdentifier.replacingOccurrences(of: "session-", with: "")
                            if let sessionId = UUID(uuidString: uuidString) {
                                // 设置要打开的会话ID
                                self.spotlightSessionId = sessionId
                            }
                        }
                    }
                }
        }
    }
}

//
//  SettingsView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/7.
//

import AcknowList
import SwiftUI

enum ChatService: String, CaseIterable {
    case ollama
}

final class AppConfiguration: ObservableObject, @unchecked Sendable {
    static let shared = AppConfiguration()
    
    @AppStorage("configuration.key") var key = ""
    
    @AppStorage("configuration.model") var model: String = ""
    
    @AppStorage("configuration.suggestionsModel") var suggestionsModel: String = ""
        
    @AppStorage("configuration.isReplySuggestionsEnabled") var isReplySuggestionsEnabled = true
        
    @AppStorage("configuration.temperature") var temperature: Double = 0.8
    
    @AppStorage("configuration.systemPrompt") var systemPrompt: String?
    
    @AppStorage("configuration.isMarkdownEnabled") var isMarkdownEnabled: Bool = true
    
    @AppStorage("configuration.preferredChatService") var preferredChatService: ChatService = .ollama
    
    @AppStorage("ollamaAPIHost") var ollamaAPIHost: String = ""
}

struct AppSettingsView: View {
    @ObservedObject var configuration: AppConfiguration
    
    @State private var selectedModel = ""
        
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    
    @State var showAPIKey = false
    
    var body: some View {
        Form {
            Section("General") {
                HStack {
                    Image(systemName: "text.bubble.fill")
                        .renderingMode(.original)
                    Toggle("Markdown Enabled", isOn: $configuration.isMarkdownEnabled)
                    Spacer()
                }
                /// Model for Suggestions
                HStack {
                    Image(systemName: "arrow.up.message")
                        .renderingMode(.original)
                    Picker("Reply Suggestions Model", selection: $configuration.suggestionsModel) {
                        ForEach(OllamaConfiguration.shared.models) { model in
                            Text(model.name).tag(model.name)
                        }
                    }
                }
            }
            Section("Model") {
                NavigationLink {
                    OllamaSettingsView()
                } label: {
                    HStack {
                        Image("ollama")
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 30, height: 30)
                        Text("Ollama")
                    }
                }
            }
            Section("Prompt") {
                NavigationLink {
                    PromptsListView()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Sync Prompts")
                    }
                }
                NavigationLink {
                    CustomPromptsView()
                } label: {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Custom Prompts")
                    }
                }
            }
            Section {
                /// AcknowList
                NavigationLink {
                    AcknowListSwiftUIView()
                } label: {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("Acknowledgements")
                    }
                }
                /// Feedback
                Button {
                    if let url = URL(string: "mailto:lhuany@gmail.com?subject=Feedback for Ollama Message") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Feedback")
                    }
                }
                .foregroundColor(.primary)
                /// AppStore Rating
                Button {
                    if let url = URL(string: "https://apps.apple.com/app/id6742433200?action=write-review") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Rate on AppStore")
                    }
                }
                .foregroundColor(.primary)
                NavigationLink {
                    AboutView()
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("About")
                    }
                }
            } header: {
                Text("")
            } footer: {
                Text("\(Bundle.main.appVersion) (\(Bundle.main.appBuild))")
            }
        }
        .onAppear {
            self.selectedModel = configuration.model
        }
        .navigationTitle("Settings")
    }
    
    private func updateModes(_ model: String) {
        configuration.model = model
        selectedModel = model
    }
}

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    var appBuild: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}

#Preview {
    NavigationStack {
        AppSettingsView(configuration: AppConfiguration())
    }
}

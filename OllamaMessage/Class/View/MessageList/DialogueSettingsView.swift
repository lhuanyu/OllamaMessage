//
//  DialogueSettingsView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/26.
//

import SwiftUI

struct DialogueSettingsView: View {
    
    @Binding var configuration: DialogueSession.Configuration
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var ollamaConfiguration = OllamaConfiguration.shared
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Model")
                        .fixedSize()
                    Spacer()
                    Picker("Model", selection: $configuration.model) {
                        ForEach(OllamaConfiguration.shared.models) { model in
                            Text(model.name)
                                .tag(model.name)
                        }
                    }
                    .labelsHidden()
                }
                VStack {
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
                HStack {
                    TextField(LocalizedStringKey("System Prompt"), text: $configuration.systemPrompt)
                }
            }
        }
        .task {
            await OllamaConfiguration.shared.fetchModels()
        }
        .navigationTitle("Settings")
    }
    
}


@available(iOS 17.0, macOS 14.0, *)
#Preview {
    
    @Previewable @State var configuration = DialogueSession.Configuration()
    
    DialogueSettingsView(configuration: $configuration)
}

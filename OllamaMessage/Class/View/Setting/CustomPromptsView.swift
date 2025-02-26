//
//  CustomPromptsView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/31.
//

import SwiftUI

struct CustomPromptsView: View {
    
    @State var showAddPromptView = false
    @ObservedObject var manager = PromptManager.shared
    
    @State var name: String = ""
    
    @State var prompt: String = ""
    
    var body: some View {
        contenView()
            .navigationTitle("Custom Prompts")
            .toolbar {
                ToolbarItem {
                    Button {
                        showAddPromptView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddPromptView) {
                NavigationStack {
                    editingPromptView
                        .navigationTitle("Add Prompt")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem {
                                Button {
                                    showAddPromptView = false
                                } label: {
                                    Text("Cancel")
                                }
                            }
                        }
                }
            }
    }
    
    @ViewBuilder
    func contenView() -> some View {
        if manager.customPrompts.isEmpty {
            VStack {
                Spacer()
                Image(systemName: "tray")
                    .font(.system(size: 50))
                    .padding()
                    .foregroundColor(.secondary)
                Text("No Prompts")
                    .font(.title3)
                    .bold()
                Spacer()
            }
        } else {
            List {
                ForEach(manager.customPrompts) { prompt in
                    NavigationLink {
                        PromptDetailView(prompt: prompt)
                    } label: {
                        Text(prompt.act)
                    }
                }
                .onDelete { indexSet in
                    withAnimation {
                        manager.removeCustomPrompts(atOffsets: indexSet)
                    }
                }
            }
        }
    }
    
    @State var selectedPrompt: Prompt?
    
    var editingPromptView: some View {
        Form {
            Section {
                HStack {
                    Text("Name")
                        .bold()
                    Spacer()
                    TextField("Type a shortcut name", text: $name)
                }
                HStack(alignment: .top) {
                    Text("Prompt")
                        .bold()
                    Spacer()
                    TextField("Type a prompt", text: $prompt, axis: .vertical)
                        .lineLimit(1...30)
                }
            }
            Section {
                Button {
                    showAddPromptView = false
                    addPrompt()
                } label: {
                    HStack {
                        Spacer()
                        Text("Confirm")
                        Spacer()
                    }
                }
                .disabled(name.isEmpty || prompt.isEmpty)
            }
        }
    }
    
    
    func addPrompt() {
        guard !name.isEmpty && !prompt.isEmpty else {
            return
        }
        withAnimation {
            manager.addCustomPrompt(.init(cmd: name.convertToSnakeCase(), act: name, prompt: prompt, tags: []))
        }
    }
    
}

struct CustomPromptsView_Previews: PreviewProvider {
    static var previews: some View {
        CustomPromptsView()
    }
}

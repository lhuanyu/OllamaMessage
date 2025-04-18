//
//  MessageListView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/3.
//

import SwiftUI
import SwiftUIIntrospect
import SwiftUIX

struct MessageListView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var session: DialogueSession
    @FocusState var isTextFieldFocused: Bool
    
    @State var isShowSettingsView = false
    
    @State var isShowClearMessagesAlert = false
    
    @State var isShowLoadingToast = false
    
    var body: some View {
        contentView
            .onDisappear {
                session.stop()
            }
            .alert(
                "Warning",
                isPresented: $isShowClearMessagesAlert
            ) {
                Button(role: .destructive) {
                    session.clearMessages()
                } label: {
                    Text("Confirm")
                }
            } message: {
                Text("Remove all messages?")
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        isShowSettingsView = true
                    } label: {
                        HStack(spacing: 0) {
                            Text(session.configuration.model)
                                .bold()
                                .foregroundColor(.label)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .sheet(isPresented: $isShowSettingsView) {
                        NavigationStack {
                            DialogueSettingsView(configuration: $session.configuration)
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem {
                                        Button {
                                            isShowSettingsView = false
                                        } label: {
                                            Text("Done")
                                                .bold()
                                        }
                                    }
                                }
                        }
                    }
                }
                if !session.conversations.isEmpty {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            guard !session.isReplying else { return }
                            isShowClearMessagesAlert = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
    }
            
    @State var keyboadWillShow = false
    
    @Namespace var animation
    
    private let bottomID = "bottomID"
    
    @State var scrollPhase = UIXScrollPhase.idle

    var contentView: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottomLeading) {
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        StatefulScrollView {
                            VStack(spacing: 0) {
                                ForEach(enumerating: Array(session.conversations.enumerated())) { index, conversation in
                                    ConversationView(
                                        conversation: conversation,
                                        namespace: animation,
                                        lastConversationDate: index > 0 ? session.conversations[index - 1].date : nil,
                                        isLastConversation: index == session.conversations.endIndex - 1,
                                        isReplying: $session.isReplying
                                    ) { conversation in
                                        Task { @MainActor in
                                            await session.retry(conversation, scroll: {
                                                scrollToBottom(proxy: proxy, anchor: $0)
                                            })
                                        }
                                    } deleteHandler: {
                                        withAnimation(after: .milliseconds(500)) {
                                            session.removeConversation(at: index)
                                            session.service.messages.remove(at: index * 2)
                                            session.service.messages.remove(at: index * 2)
                                        }
                                    }
                                    .id(index)
                                }
                                if session.conversations.isEmpty {
                                    Color.clear
                                        .frame(height: geo.size.height - 44)
                                }
                                        
                                Spacer(minLength: 0)
                                ScrollView(.horizontal) {
                                    HStack {
                                        ForEach(session.suggestions, id: \.self) { suggestion in
                                            Button {
                                                selectedPromptIndex = nil
                                                session.input = suggestion
                                                sendMessage(proxy)
                                            } label: {
                                                Text(suggestion)
                                                    .lineLimit(1)
                                            }
                                            .padding()
                                        }
                                    }
                                }
                                .scrollIndicators(.never)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .id(bottomID)
                            }
                            .frame(minHeight: geo.size.height)
                        }
                        .onPreferenceChange(ScrollPhasePreferenceKey.self) { phase in
                            print(phase)
                            Task { @MainActor in
                                scrollPhase = phase
                            }
                        }
                        .onTapGesture {
                            isTextFieldFocused = false
                        }
                    }
                    BottomInputView(
                        session: session,
                        isLoading: $isShowLoadingToast,
                        namespace: animation,
                        isTextFieldFocused: _isTextFieldFocused
                    ) { _ in
                        sendMessage(proxy)
                    }
                }
                promptListView()
            }
            .onReceive(keyboardWillChangePublisher) { value in
                if isTextFieldFocused, value {
                    self.keyboadWillShow = value
                }
            }.onReceive(keyboardDidChangePublisher) { value in
                if isTextFieldFocused {
                    if value {
                        withAnimation(.easeOut(duration: 0.1)) {
                            scrollToBottom(proxy: proxy)
                        }
                    } else {
                        self.keyboadWillShow = false
                    }
                }
            }
            .onAppear {
                scrollToBottom(proxy: proxy)
                if session.title == nil {
                    session.createTitle()
                }
                if session.suggestions.isEmpty {
                    session.createSuggestions()
                }
                if session.conversations.isEmpty {
                    isTextFieldFocused = true
                }
            }
            .onChange(of: session) { session in
                scrollToBottom(proxy: proxy)
                if session.suggestions.isEmpty {
                    session.createSuggestions()
                }
            }
            .onChange(of: selectedPromptIndex, perform: onSelectedPromptIndexChange)
            .onChange(of: session.input) { _ in
                withAnimation {
                    filterPrompts()
                }
            }
            .onChange(of: session.inputData) { data in
                if let _ = data {
                    withAnimation(after: .milliseconds(100)) {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
        }
    }
    
    func sendMessage(_ proxy: ScrollViewProxy) {
        if session.isReplying {
            return
        }
        Task { @MainActor in
            if let selectedPromptIndex = selectedPromptIndex, selectedPromptIndex < prompts.endIndex {
                userHasChangedSelection = false
                session.bubbleText = prompts[selectedPromptIndex].prompt
                session.input = prompts[selectedPromptIndex].prompt
                self.selectedPromptIndex = nil
            } else {
                session.bubbleText = session.input
            }
            session.isSending = true
            await session.send {
                scrollToBottom(proxy: proxy, anchor: $0)
            }
        }
    }
    
    @MainActor
    private func scrollToBottom(proxy: ScrollViewProxy, anchor: UnitPoint = .bottom) {
        if scrollPhase == .idle || scrollPhase == .animating {
            proxy.scrollTo(bottomID, anchor: anchor)
        }
    }
    
    // MARK: - Search Prompt
        
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @ViewBuilder
    private func promptListView() -> some View {
        if session.input.hasPrefix("/") {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                ScrollViewReader { _ in
                    List(selection: $selectedPromptIndex) {
                        if prompts.isEmpty {
                            Text("No Result")
                                .foregroundColor(.secondaryLabel)
                        } else {
                            ForEach(prompts.indices, id: \.self) { index in
                                let prompt = prompts[index]
                                HStack {
                                    Text("/\(prompt.cmd)")
                                        .lineLimit(1)
                                        .bold()
                                    if horizontalSizeClass == .regular {
                                        Spacer()
                                        Text(prompt.act)
                                            .lineLimit(1)
                                            .foregroundColor(.secondaryLabel)
                                    }
                                }
                                .id(index)
                                .tag(index)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.systemBackground)
                    .border(.blue, width: 2)
                    .frame(height: promptListHeight)
                }
            }
            .frame(minWidth: promptListMinWidth, maxHeight: .infinity)
            .padding(.leading, promptListLeadingPadding)
            .padding(.trailing, promptListTrailingPadding)
            .padding(.bottom, 50)
        } else {
            EmptyView()
        }
    }
    
    private var promptListTrailingPadding: CGFloat {
        16
    }
    
    private var promptListLeadingPadding: CGFloat {
        horizontalSizeClass == .regular ? 110 : 16
    }
    
    private var promptListMinWidth: CGFloat {
        0
    }
    
    private var promptListHeight: CGFloat {
        if verticalSizeClass == .compact, isTextFieldFocused {
            return min(88, max(CGFloat(prompts.count * 44), 44))
        } else {
            return min(220, max(CGFloat(prompts.count * 44), 44))
        }
    }
    
    @State var selectedPromptIndex: Int?
    
    @State var userHasChangedSelection = false
    
    @State var prompts = PromptManager.shared.prompts
    
    private func filterPrompts() {
        guard session.input.hasPrefix("/") else {
            selectedPromptIndex = nil
            userHasChangedSelection = false
            return
        }
        
        if let selectedPromptIndex = selectedPromptIndex, prompts.endIndex > selectedPromptIndex {
            let input = session.input.dropFirst()
            if prompts[selectedPromptIndex].cmd == input {
                return
            }
        }
        
        if session.input == "/" {
            prompts = PromptManager.shared.prompts
        } else {
            let input = session.input.dropFirst()
            prompts = PromptManager.shared.prompts.filter { prompt in
                let p = prompt.cmd.lowercased().replacingOccurrences(of: "_", with: "")
                return p.range(of: input.lowercased()) != nil || prompt.cmd.lowercased().range(of: input.lowercased()) != nil
            }
        }
    }
    
    private func onSelectedPromptIndexChange(_ index: Int?) {
        if let index = index, index < prompts.endIndex {
            session.input = prompts[index].prompt
        }
    }
}

extension MessageListView: KeyboardReadable {}

@available(iOS 17.0, *)
#Preview {
    @Previewable var session: DialogueSession = {
        let session = DialogueSession()
        session.conversations = Conversation.samples
        return session
    }()
    
    NavigationView {
        MessageListView(session: session)
    }
}

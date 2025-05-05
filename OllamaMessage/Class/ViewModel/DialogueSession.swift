//
//  DialogueSession.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/3.
//

import AudioToolbox
import Foundation
import SwiftUI
import SwiftUIX

class DialogueSession: ObservableObject, Identifiable, Equatable, Hashable, Codable {
    struct Configuration: Codable {
        var key: String {
            AppConfiguration.shared.key
        }

        var model: String = ""

        var ollamaModelProvider: OllamaModelProvider {
            model.ollamaModelProvider
        }

        var temperature: Double = 0.8

        var numCtx: Int = 4096

        var systemPrompt: String?

        init() {
            model = AppConfiguration.shared.model
            temperature = OllamaConfiguration.shared.temperature
            numCtx = OllamaConfiguration.shared.numCtx
            systemPrompt = AppConfiguration.shared.systemPrompt
        }
    }

    // MARK: - Codable

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        configuration = try container.decode(Configuration.self, forKey: .configuration)
        conversations = try container.decode([Conversation].self, forKey: .conversations)
        date = try container.decode(Date.self, forKey: .date)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        let messages = try container.decode([Message].self, forKey: .messages)

        isReplying = false
        isStreaming = false
        input = ""
        service = OllamaService(configuration: configuration)
        service.messages = messages
        initFinished = true
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(configuration, forKey: .configuration)
        try container.encode(conversations, forKey: .conversations)
        try container.encode(service.messages, forKey: .messages)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(title, forKey: .title)
    }

    enum CodingKeys: CodingKey {
        case configuration
        case conversations
        case messages
        case date
        case id
        case title
    }

    // MARK: - Hashable, Equatable

    static func == (lhs: DialogueSession, rhs: DialogueSession) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var id = UUID()

    var rawData: DialogueData?

    // MARK: - State

    @Published var isReplying: Bool = false
    @Published var isSending: Bool = false
    @Published var bubbleText: String = ""
    @Published var isStreaming: Bool = false
    @Published var input: String = ""
    @Published var inputData: Data?
    @Published var sendingData: Data?
    @Published var title: String?
    @Published var conversations: [Conversation] = [] {
        didSet {
            if let date = conversations.last?.date {
                self.date = date
            }
        }
    }

    @Published var suggestions: [String] = []
    @Published var date = Date()

    private var initFinished = false

    @MainActor func stop() {
        guard isReplying else {
            return
        }
        hasCanceled = true
        stopStreaming()
    }

    // MARK: - Properties

    @Published var configuration: Configuration = .init() {
        didSet {
            service.configuration = configuration
            save()
        }
    }

    var lastMessage: String {
        return conversations.last?.preview ?? ""
    }

    lazy var service = OllamaService(configuration: configuration)

    init() {}

    // MARK: - Message Actions

    @MainActor
    func send(scroll: ((UnitPoint) -> Void)? = nil) async {
        if let inputData = inputData {
            sendingData = inputData
            self.inputData = nil
            let text = input
            input = ""
            await send(text: text, data: sendingData, scroll: scroll)
        } else {
            let text = input
            input = ""
            await send(text: text, scroll: scroll)
        }
    }

    @MainActor
    func clearMessages() {
        service.removeAllMessages()
        title = nil
        withAnimation { [weak self] in
            self?.removeAllConversations()
            self?.suggestions.removeAll()
        }
    }

    @MainActor
    func retry(_ conversation: Conversation, scroll: ((UnitPoint) -> Void)? = nil) async {
        removeConversation(conversation)
        service.messages.removeLast()
        await send(
            text: conversation.input, data: conversation.inputData, isRetry: true, scroll: scroll)
    }

    private var lastConversationData: ConversationData?

    private var hasCanceled = false

    @MainActor
    private func send(
        text: String, data: Data? = nil, isRetry: Bool = false, scroll: ((UnitPoint) -> Void)? = nil
    ) async {
        var streamText = ""
        var conversation = Conversation(
            isLast: true,
            input: text,
            inputData: data,
            reply: "",
            errorDesc: nil)

        if conversations.count > 0 {
            conversations[conversations.endIndex - 1].isLast = false
        }

        if isRetry {
            suggestions.removeAll()
            isReplying = true
            lastConversationData = appendConversation(conversation)
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                suggestions.removeAll()
                isReplying = true
                lastConversationData = appendConversation(conversation)
                scroll?(.bottom)
            }
        }

        AudioServicesPlaySystemSound(1004)

        do {
            try await Task.sleep(for: .milliseconds(260))
            isSending = false
            bubbleText = ""
            sendingData = nil

            withAnimation {
                scroll?(.top)
                scroll?(.bottom)
            }

            let stream = try await service.sendMessage(text, data: data)

            if hasCanceled {
                print("Reply Canceled")
                hasCanceled = false
                isReplying = false
                return
            }

            isStreaming = true
            AudioServicesPlaySystemSound(1301)
            for try await text in stream {
                streamText += text
                conversation.reply = streamText
                conversations[conversations.count - 1] = conversation

                withAnimation {
                    if #available(iOS 17, *) {
                        scroll?(.bottom)
                    } else {
                        scroll?(.top)
                        /// for an issue of iOS 16
                        scroll?(.bottom)
                    }
                }
            }

            lastConversationData?.sync(with: conversation)
            isStreaming = false
            createTitle()
            createSuggestions()
        } catch {
            withAnimation {
                hasCanceled = false
                isStreaming = false
                conversation.errorDesc = error.localizedDescription
                lastConversationData?.sync(with: conversation)
                scroll?(.bottom)
            }
        }

        withAnimation {
            updateLastConversation(conversation)
            isReplying = false
            scroll?(.bottom)
            save()
        }
    }

    @MainActor
    func stopStreaming() {
        service.stopStreaming()
    }

    @MainActor
    func createTitle() {
        Task { @MainActor in
            do {
                if let title = try await service.createTitle() {
                    withoutAnimation {
                        self.title = title
                        self.save()

                        // Update search index when title is created
                        AppSearchHandler.shared.indexDialogueSession(self)
                    }
                }
            } catch {
                print(error)
            }
        }
    }

    @MainActor
    func createSuggestions() {
        guard AppConfiguration.shared.isReplySuggestionsEnabled else {
            return
        }
        Task { @MainActor in
            do {
                let suggestions = try await service.createSuggestions()
                if isReplying {
                    return
                }
                withAnimation {
                    self.suggestions = suggestions
                }
            } catch {
                print(error)
            }
        }
    }
}

extension DialogueSession {
    convenience init?(rawData: DialogueData) {
        self.init()
        guard let id = rawData.id,
            let date = rawData.date,
            let configurationData = rawData.configuration,
            let conversations = rawData.conversations as? Set<ConversationData>
        else {
            return nil
        }
        self.rawData = rawData
        self.id = id
        self.date = date
        title = rawData.title
        if let configuration = try? JSONDecoder().decode(
            Configuration.self, from: configurationData)
        {
            self.configuration = configuration
        }

        self.conversations = conversations.compactMap { data in
            if let id = data.id,
                let input = data.input,
                let date = data.date
            {
                let conversation = Conversation(
                    id: id,
                    input: input,
                    inputData: data.inputData,
                    reply: data.reply,
                    replyData: data.replyData,
                    errorDesc: data.errorDesc,
                    date: date)
                return conversation
            } else {
                return nil
            }
        }
        self.conversations.sort {
            $0.date < $1.date
        }

        for conversation in self.conversations {
            service.appendNewMessage(
                input: conversation.inputType.isImage ? "An image" : conversation.input,
                reply: conversation.replyType.isImage ? "An image" : conversation.reply ?? "")
        }
        if !self.conversations.isEmpty {
            self.conversations[self.conversations.endIndex - 1].isLast = true
        }
        initFinished = true
    }

    @discardableResult
    func appendConversation(_ conversation: Conversation) -> ConversationData {
        conversations.append(conversation)
        let data = ConversationData(context: PersistenceController.shared.container.viewContext)
        data.id = conversation.id
        data.date = conversation.date
        data.input = conversation.input
        data.reply = conversation.reply
        rawData?.conversations?.adding(data)
        data.dialogue = rawData

        do {
            try PersistenceController.shared.save()
        } catch {
            print(error.localizedDescription)
        }

        return data
    }

    func updateLastConversation(_ conversation: Conversation) {
        conversations[conversations.count - 1] = conversation
        lastConversationData?.sync(with: conversation)
    }

    func removeConversation(_ conversation: Conversation) {
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else {
            return
        }
        removeConversation(at: index)
    }

    func removeConversation(at index: Int) {
        let isLast = conversations.endIndex - 1 == index
        let conversation = conversations.remove(at: index)
        if isLast, !conversations.isEmpty {
            conversations[conversations.endIndex - 1].isLast = true
            suggestions.removeAll()
        }
        do {
            if let conversationsSet = rawData?.conversations as? Set<ConversationData>,
                let conversationData = conversationsSet.first(where: {
                    $0.id == conversation.id
                })
            {
                PersistenceController.shared.container.viewContext.delete(conversationData)
            }
            try PersistenceController.shared.save()
        } catch {
            print(error.localizedDescription)
        }
    }

    func removeAllConversations() {
        conversations.removeAll()
        do {
            let viewContext = PersistenceController.shared.container.viewContext
            if let conversations = rawData?.conversations as? Set<ConversationData> {
                conversations.forEach(viewContext.delete)
            }
            try PersistenceController.shared.save()

            // Remove from search index when all conversations are deleted
            AppSearchHandler.shared.deindexDialogueSession(self)
        } catch {
            print(error.localizedDescription)
        }
    }

    func save() {
        guard initFinished else {
            return
        }
        do {
            rawData?.date = date
            rawData?.title = title
            rawData?.configuration = try JSONEncoder().encode(configuration)
            try PersistenceController.shared.save()

            // Update search index when session is saved
            if title != nil && !conversations.isEmpty {
                AppSearchHandler.shared.indexDialogueSession(self)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension ConversationData {
    func sync(with conversation: Conversation) {
        id = conversation.id
        date = conversation.date
        input = conversation.input
        inputData = conversation.inputData
        reply = conversation.reply
        replyData = conversation.replyData
        errorDesc = conversation.errorDesc
        do {
            try PersistenceController.shared.save()
        } catch {
            print(error.localizedDescription)
        }
    }
}

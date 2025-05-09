//
//  ConversationView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/3.
//

import Kingfisher
import SwiftUI
import SwiftUIX

enum AnimationID {
    static let senderBubble = "SenderBubble"
}

struct ConversationView: View {
    let conversation: Conversation
    let namespace: Namespace.ID
    var lastConversationDate: Date?
    var isLastConversation: Bool = false
    @Binding var isReplying: Bool
    let retryHandler: (Conversation) -> Void
    
    @State var isEditing = false
    @FocusState var isFocused: Bool
    @State var editingMessage: String = ""
    var deleteHandler: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            dateView
            VStack {
                message(isSender: true)
                    .padding(.leading, horizontalPadding(for: conversation.inputType)).padding(.vertical, 10)
                if conversation.reply != nil {
                    message()
                        .transition(.move(edge: .leading))
                        .padding(.trailing, horizontalPadding(for: conversation.replyType)).padding(.vertical, 10)
                }
            }
        }
        .transition(.moveAndFade)
        .padding(.horizontal, 15)
    }
    
    private func horizontalPadding(for type: MessageType) -> CGFloat {
        type.isImage ? 105 : 55
    }
    
    var dateView: some View {
        HStack {
            Spacer()
            if let lastConversationDate = lastConversationDate {
                if conversation.date.timeIntervalSince(lastConversationDate) > 60 {
                    Text(conversation.date.iMessageDateTimeString)
                        .font(.footnote)
                        .foregroundColor(.secondaryLabel)
                }
            } else {
                Text(conversation.date.iMessageDateTimeString)
                    .font(.footnote)
                    .foregroundColor(.secondaryLabel)
            }
            Spacer()
        }
        .padding(.top, 10)
    }
    
    private var showRefreshButton: Bool {
        !isReplying && conversation.isLast
    }
    
    @ViewBuilder
    func message(isSender: Bool = false) -> some View {
        if isSender {
            senderMessage
                .contextMenu {
                    Button {
                        if let data = conversation.inputData {
                            KFCrossPlatformImage(data: data)?.copyToPasteboard()
                        } else {
                            conversation.input.copyToPasteboard()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                    }
                    if !isReplying {
                        Button(role: .destructive) {
                            deleteHandler?()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                        }
                    }
                }
        } else {
            replyMessage
                .contextMenu {
                    VStack {
                        Button {
                            if let imageURL = conversation.replyImageURL {
                                ImageCache.default.retrieveImage(forKey: imageURL.absoluteString) { result in
                                    switch result {
                                    case let .success(image):
                                        image.image?.copyToPasteboard()
                                        print("copied!")
                                    case .failure:
                                        break
                                    }
                                }
                            } else if let data = conversation.replyImageData {
                                KFCrossPlatformImage(data: data)?.copyToPasteboard()
                            } else {
                                conversation.reply?.copyToPasteboard()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                        }
                        if conversation.isLast {
                            Button {
                                retryHandler(conversation)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Regenerate")
                                }
                            }
                        }
                        if !isReplying {
                            Button(role: .destructive) {
                                deleteHandler?()
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete")
                                }
                            }
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    var senderMessage: some View {
        HStack(spacing: 0) {
            Spacer()
            if conversation.isLast {
                messageEditButton()
                senderMessageContent
                    .frame(minHeight: 24)
                    .bubbleStyle(isMyMessage: true, type: conversation.inputType)
                    .matchedGeometryEffect(id: AnimationID.senderBubble, in: namespace)
            } else {
                senderMessageContent
                    .frame(minHeight: 24)
                    .bubbleStyle(isMyMessage: true, type: conversation.inputType)
            }
        }
        if conversation.inputData != nil && !conversation.input.isEmpty {
            HStack(spacing: 0) {
                Spacer()
                Text(conversation.input)
                    .textSelection(.enabled)
                    .frame(minHeight: 24)
                    .bubbleStyle(isMyMessage: true, type: .text)
            }
        }
    }
    
    @ViewBuilder
    var senderMessageContent: some View {
        if let data = conversation.inputData {
            ImageDataMessageView(data: data)
                .maxWidth(256)
        } else {
            if isEditing {
                TextField("", text: $editingMessage, axis: .vertical)
                    .foregroundColor(.primary)
                    .focused($isFocused)
                    .lineLimit(1 ... 20)
                    .background(.background)
            } else {
                Text(conversation.input)
                    .textSelection(.enabled)
            }
        }
    }
    
    @ViewBuilder
    func messageEditButton() -> some View {
        if isReplying || conversation.inputType.isImage {
            EmptyView()
        } else {
            Button {
                if isEditing {
                    if editingMessage != conversation.input {
                        var message = conversation
                        message.input = editingMessage
                        retryHandler(message)
                    }
                } else {
                    editingMessage = conversation.input
                }
                isEditing.toggle()
                isFocused = isEditing
            } label: {
                if isEditing {
                    Image(systemName: "checkmark")
                } else {
                    Image(systemName: "pencil")
                }
            }
            .keyboardShortcut(isEditing ? .defaultAction : .none)
            .frame(width: 30)
            .padding(.trailing)
            .padding(.leading, -50)
        }
    }
    
    var replyMessage: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                switch conversation.replyType {
                case .text:
                    if let reply = conversation.reply {
                        let components = reply.components(separatedBy: "</think>")
                        if components.count > 1,
                           let think = components.first?.trimmingPrefix("<think>").trimmingCharacters(in: .whitespacesAndNewlines),
                           let text = components.last
                        {
                            TextMessageView(
                                think: String(think),
                                text: text,
                                isReplying: isReplying && isLastConversation)
                        } else if reply.hasPrefix("<think>") {
                            let think = reply.trimmingPrefix("<think>").trimmingCharacters(in: .whitespacesAndNewlines)
                            TextMessageView(
                                think: String(think),
                                text: "",
                                isReplying: isReplying && isLastConversation)
                        } else {
                            TextMessageView(text: reply, isReplying: isReplying && isLastConversation)
                        }
                    } else {
                        TextMessageView(text: "", isReplying: isReplying && isLastConversation)
                    }
                case .image:
                    ImageMessageView(url: conversation.replyImageURL)
                        .maxWidth(256)
                case .imageData:
                    ImageDataMessageView(data: conversation.replyImageData)
                        .maxWidth(256)
                case .error:
                    ErrorMessageView(error: conversation.errorDesc) {
                        retryHandler(conversation)
                    }
                }
                if isReplying && isLastConversation {
                    ReplyingIndicatorView()
                        .frame(width: 48, height: 24)
                }
            }
            .frame(minHeight: 24)
            .bubbleStyle(isMyMessage: false, type: conversation.replyType)
            retryButton
            Spacer()
        }
    }
    
    @ViewBuilder
    var retryButton: some View {
        if !isReplying {
            if conversation.errorDesc == nil && conversation.isLast {
                Button {
                    retryHandler(conversation)
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .frame(width: 30)
                .padding(.leading)
                .padding(.trailing, -50)
            }
        }
    }
}

extension String {
    func copyToPasteboard() {
        UIPasteboard.general.string = self
    }
}

extension KFCrossPlatformImage {
    func copyToPasteboard() {
        UIPasteboard.general.image = self
    }
}

extension AnyTransition {
    static var moveAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom),
            removal: .move(edge: .top).combined(with: .opacity))
    }
}

struct MessageRowView_Previews: PreviewProvider {
    static let message = Conversation(
        isLast: false,
        input: "What is SwiftUI?",
        reply: "SwiftUI is a user interface framework that allows developers to design and develop user interfaces for iOS, macOS, watchOS, and tvOS applications using Swift, a programming language developed by Apple Inc.")
    
    static let message2 = Conversation(
        isLast: false,
        input: "What is SwiftUI?",
        reply: "",
        errorDesc: "OllamaMessage is currently not available")
    
    static let message3 = Conversation(
        isLast: false,
        input: "What is SwiftUI?",
        reply: "")
    
    static let message4 = Conversation(
        isLast: true,
        input: "What is SwiftUI?",
        reply: "SwiftUI is a user interface framework that allows developers to design and develop user interfaces for iOS, macOS, watchOS, and tvOS applications using Swift, a programming language developed by Apple Inc.",
        errorDesc: nil)
    
    @Namespace static var animation
    
    static var previews: some View {
        NavigationStack {
            ScrollView {
                ConversationView(
                    conversation: message,
                    namespace: animation,
                    isReplying: .constant(false),
                    retryHandler: { _ in
                    
                    })
                ConversationView(
                    conversation: message2,
                    namespace: animation,
                    isReplying: .constant(false),
                    retryHandler: { _ in
                    
                    })
                ConversationView(
                    conversation: message3,
                    namespace: animation,
                    isReplying: .constant(false), retryHandler: { _ in
                    
                    })
                ConversationView(
                    conversation: message4,
                    namespace: animation,
                    isReplying: .constant(false),
                    retryHandler: { _ in
                    
                    })
            }
            .frame(width: 400)
            .previewLayout(.sizeThatFits)
        }
    }
}

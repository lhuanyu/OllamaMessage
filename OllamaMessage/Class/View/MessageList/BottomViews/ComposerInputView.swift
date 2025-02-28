//
//  ComposerInputView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/17.
//

import SwiftUI

struct ComposerInputView: View {
    @ObservedObject var session: DialogueSession
    @ObservedObject var recognizer = SpeechRecognizer.shared
    @FocusState var isTextFieldFocused: Bool
    
    let namespace: Namespace.ID
    
    var send: (String) -> Void
    
    private var size: CGFloat {
        26
    }
    
    var radius: CGFloat {
        17
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            textField
            if let data = session.sendingData {
                animationImageView(data)
            } else if let data = session.inputData {
                VStack {
                    imageView(data)
                    Divider()
                    TextField("", text: $session.input, axis: .vertical)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...1)
                        .padding(.leading, 12)
                        .padding(.trailing, size + 6)
                }
            } else if session.isSending {
                animationTextView
            }
            sendButton
        }
        .padding(4)
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(.tertiary, lineWidth: 1)
                .opacity(0.7)
        )
        .padding([.trailing])
    }
    
    private var textFieldHint: LocalizedStringKey {
        if isRecording {
            return "Speech Reconginizing..."
        } else {
            return "Ask anything, or type /"
        }
    }
    
    @ViewBuilder
    private var textField: some View {
        if session.inputData == nil {
            TextField(textFieldHint, text: $session.input, axis: .vertical)
                .focused($isTextFieldFocused)
                .multilineTextAlignment(.leading)
                .lineLimit(1...20)
                .padding(.leading, 12)
                .padding(.trailing, size + 6)
                .frame(minHeight: size)
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func animationImageView(_ data: Data) -> some View {
        HStack {
            Image(data: data)?
                .resizable()
                .scaledToFit()
                .bubbleStyle(isMyMessage: true, type: .imageData)
                .matchedGeometryEffect(id: AnimationID.senderBubble, in: namespace)
            Spacer(minLength: 80)
        }
    }
    
    @ViewBuilder
    private func imageView(_ data: Data) -> some View {
        HStack {
            ZStack(alignment: .topTrailing) {
                Image(data: data)?
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(radius)
                Button {
                    withAnimation {
                        session.inputData = nil
                    }
                } label: {
                    ZStack {
                        Color.white
                            .frame(width: 20, height: 20)
                            .cornerRadius(10)
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.systemGray)
                    }
                }
                .padding([.top, .trailing], 6)
            }
            Spacer(minLength: 80)
        }
    }
    
    private var animationTextView: some View {
        Text("\(session.bubbleText)")
            .frame(maxWidth: .infinity, minHeight: radius * 2 - 8, alignment: .leading)
            .bubbleStyle(isMyMessage: true)
            .matchedGeometryEffect(id: AnimationID.senderBubble, in: namespace)
            .padding(-4)
    }
    
    @ViewBuilder
    private var sendButton: some View {
        if (!session.input.isEmpty || session.inputData != nil) && !isRecording {
            Button {
                send(session.input)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundColor(.blue)
                    .font(.body.weight(.semibold))
            }
            .keyboardShortcut(.return)
        } else {
            if session.isStreaming {
                Button {
                    session.stopStreaming()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.accentColor)
                }
                .offset(x: -2, y: 0)
            } else {
                Button {
                    if isRecording {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        SpeechRecognizer.shared.stopRecording()
                        isRecording = false
                    } else {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        let recordingStarted = SpeechRecognizer.shared.startRecording()
                        if recordingStarted {
                            isRecording = true
                        }
                    }
                } label: {
                    if #available(iOS 17.0, *) {
                        if isRecording {
                            Image(systemName: "mic.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(.accentColor)
                                .opacity(1)
                                .symbolEffect(.pulse)
                        } else {
                            Image(systemName: "mic")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(.secondary)
                                .opacity(0.7)
                        }
                    } else {
                        if isRecording {
                            Image(systemName: "mic")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(.accentColor)
                                .opacity(1)
                                .pulse()
                        } else {
                            Image(systemName: "mic")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(.secondary)
                                .opacity(0.7)
                        }
                    }
                }
                .offset(x: -4, y: -4)
                .onChange(of: SpeechRecognizer.shared.transcribedText) { transcribedText in
                    session.input = transcribedText
                }
            }
        }
    }
    
    @State private var isRecording = false
}

struct ComposerInputView_Previews: PreviewProvider {
    @Namespace static var namespace
    
    static var previews: some View {
        ComposerInputView(session: .init(), namespace: namespace) { _ in
        }
    }
}

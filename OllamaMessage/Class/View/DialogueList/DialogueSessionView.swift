//
//  DialogueSessionView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/3/6.
//

import SwiftUI
import Kingfisher

struct DialogueSessionView: View {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass

    private var shouldShowIcon: Bool {
        verticalSizeClass != .compact
    }
    
    @ObservedObject var session: DialogueSession
    
    var body: some View {
        HStack {
            if shouldShowIcon {
                KFImage.url(session.configuration.model.ollamaModelProvider.iconURL)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .cornerRadius(20)
                    .padding()
            }
            VStack(alignment: .leading, spacing: 4) {
                NavigationLink(value: session) {
                    HStack {
                        Text(session.configuration.model)
                            .bold()
                            .font(Font.system(.headline))
                        Spacer()
                        Text(session.date.dialogueDesc)
                            .font(Font.system(.subheadline))
                            .foregroundColor(.secondary)
                    }
                }
                if let title = session.title {
                    Text(title)
                        .font(Font.system(.subheadline))
                        .lineLimit(1)
                }
                HStack {
                    Text(session.lastMessage)
                        .font(Font.system(.body))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .topLeading
                        )
                }
                .frame(height: 44)
            }
        }
    }
}

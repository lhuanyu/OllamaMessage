//
//  TextMessageView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/4/6.
//

import SwiftUI

struct TextMessageView: View {
    var think: String?
    var text: String
    var isReplying: Bool
    
    @EnvironmentObject var appConfiguration: AppConfiguration

    var body: some View {
        if appConfiguration.isMarkdownEnabled {
            MessageMarkdownView(
                think: think,
                text: text,
                isReplying: isReplying
            )
            .textSelection(.enabled)
        } else {
            if text.isEmpty {
                EmptyView()
            } else {
                Text(text)
                    .textSelection(.enabled)
            }
        }
    }
}

#Preview {
    TextMessageView(text: "Test", isReplying: false)
}

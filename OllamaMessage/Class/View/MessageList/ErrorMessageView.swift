//
//  ErrorMessageView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/4/6.
//

import SwiftUI

struct ErrorMessageView: View {
    var error: String?
    var retryHandler: (() -> Void)?

    var body: some View {
        if let error = error {
            Text("Error: \(error)")
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
            Button {
                retryHandler?()
            } label: {
                Text("Regenerate response")
            }
            .foregroundColor(.accentColor)
            .padding([.top, .bottom])
        }
    }
}

#Preview {
    ErrorMessageView()
}

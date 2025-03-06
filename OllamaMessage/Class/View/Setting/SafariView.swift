//
//  SafariView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/3/3.
//

import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
    var url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    SafariView(url: URL(string: "https://www.apple.com")!)
}

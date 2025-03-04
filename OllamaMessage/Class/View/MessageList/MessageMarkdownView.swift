//
//  MessageMarkdownView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/7.
//

import MarkdownUI
import Splash
import SwiftUI

struct MessageMarkdownView: View {
    @Environment(\.colorScheme) private var colorScheme

    var think: String?

    var text: String

    var isReplying: Bool

    @State private var isThinkingExpanded = false

    var body: some View {
        VStack(alignment: .leading) {
            if let think = think, !think.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation {
                            self.isThinkingExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.right")
                                .frame(width: 14, height: 14)
                                .rotationEffect(.degrees(self.isThinkingExpanded ? 90 : 0))
                                .foregroundColor(.secondary)
                                .padding(.leading)
                            Text("Reasoning Thinking")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                    if self.isThinkingExpanded || self.isReplying {
                        Text(think)
                            .padding(.horizontal)
                            .padding(.bottom)
                            .foregroundColor(.secondary)
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.vertical)
                .disabled(self.isReplying)
            }
            if !self.text.isEmpty {
                Markdown(MarkdownContent(self.text))
                    .markdownImageProvider(.webImage)
                    .markdownBlockStyle(\.codeBlock, body: { configuration in
                        configuration.label
                            .codeBlockTitleView(configuration.language ?? "", content: configuration.content)
                    })
                    .markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
                    .textSelection(.enabled)
            }
        }
        .onAppear {
            if self.isReplying {
                self.isThinkingExpanded = true
            }
        }
    }

    private var theme: Splash.Theme {
        // NOTE: We are ignoring the Splash theme font
        switch self.colorScheme {
        case .dark:
            return .wwdc17(withFont: .init(size: 16))
        default:
            return .sunset(withFont: .init(size: 16))
        }
    }
}

// MARK: - WebImageProvider

struct WebImageProvider: ImageProvider {
    func makeImage(url: URL?) -> some View {
        ResizeToFit {
            AsyncImage(url: url) { image in
                image
                    .resizable()
            } placeholder: {
                ProgressView()
            }
        }
    }
}

extension ImageProvider where Self == WebImageProvider {
    static var webImage: Self {
        .init()
    }
}

// MARK: - ResizeToFit

/// A layout that resizes its content to fit the container **only** if the content width is greater than the container width.
struct ResizeToFit: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let view = subviews.first else {
            return .zero
        }

        var size = view.sizeThatFits(.unspecified)

        if let width = proposal.width, size.width > width {
            let aspectRatio = size.width / size.height
            size.width = width
            size.height = width / aspectRatio
        }
        return size
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        guard let view = subviews.first else { return }
        view.place(at: bounds.origin, proposal: .init(bounds.size))
    }
}

extension View {
    func codeBlockTitleView(_ language: String, content: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(language.firstUppercased)
                    .font(.system(size: 14, weight: .bold))
                    .padding(.leading)
                Spacer()
                Button {
                    UIPasteboard.general.string = content
                } label: {
                    HStack {
                        Image(systemName: "square.on.square")
                        Text("Copy")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                }
                .frame(height: 44)
            }
            .frame(height: 44)
            .background(Color(.systemGray6))
            .cornerRadius([.topLeading, .topTrailing], 8)
            ScrollView(.horizontal) {
                self
                    .monospaced()
                    .padding()
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

extension String {
    var firstUppercased: String {
        guard let first = first else { return self }
        return String(first).uppercased() + dropFirst()
    }
}

#Preview {
    MessageMarkdownView(text: """
    # 定义图片链接和替代文本
    ```python
    image_url = "https://images.unsplash.com/photo-1582709684359-ebf7b72cbad6?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max"
    alt_text = "美丽的风景"

    # 定义Markdown内容
    markdown_content = f"![{alt_text}]({image_url})\n\n这是一个包含图片的Markdown文件。"

    # 创建并写入Markdown文件
    with open("output.md", "w", encoding="utf-8") as file:
        file.write(markdown_content)

    print("Markdown 文件已生成")
    ```
    """, isReplying: false)
        .padding()
}

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
                            isThinkingExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.right")
                                .frame(width: 14, height: 14)
                                .rotationEffect(.degrees(isThinkingExpanded ? 90 : 0))
                                .foregroundColor(.secondary)
                                .padding(.leading)
                            Text("Reasoning Thinking")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                    if isThinkingExpanded || isReplying {
                        Text(think)
                            .padding(.horizontal)
                            .padding(.bottom)
                            .foregroundColor(.secondary)
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.vertical)
                .disabled(isReplying)
            }
            if !self.text.isEmpty {
                Markdown(MarkdownContent(self.text))
                    .markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
                    .markdownImageProvider(.webImage)
                    .textSelection(.enabled)
            }
        }
        .onAppear {
            if isReplying {
                isThinkingExpanded = true
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

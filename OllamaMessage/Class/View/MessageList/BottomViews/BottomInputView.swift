//
//  BottomInputView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/23.
//

import SwiftUI
import SwiftUIX

struct BottomInputView: View {
    
    @ObservedObject var session: DialogueSession
    @Binding var isLoading: Bool
    @Environment(\.colorScheme) var colorScheme

    let namespace: Namespace.ID
    
    @FocusState var isTextFieldFocused: Bool
        
    var send: (String) -> Void
        
    var body: some View {
        HStack(alignment: .bottom) {
            LeadingComposerView(session: session, isLoading: $isLoading)
                .fixedSize()
                .alignmentGuide(.bottom, computeValue: { d in
                    d[.bottom] - d.height * 0.5 + leadingComposerDelta
                })
                .padding([.leading])
            ZStack {
                ComposerInputView(
                    session: session,
                    isTextFieldFocused: _isTextFieldFocused,
                    namespace: namespace,
                    send: send
                )
            }
        }
        .padding([.top, .bottom], 6)
        .background{
            if colorScheme == .light {
                BlurEffectView(style: .light)
                    .edgesIgnoringSafeArea(.bottom)
            } else {
                BlurEffectView(style: .systemUltraThinMaterialDark)
                    .edgesIgnoringSafeArea(.bottom)
            }
        }
    }
    
    
    private let leadingComposerDelta: CGFloat = 17
    
    
}

@available(iOS 17.0, macOS 14.0, *)
#Preview {
    @Previewable @Namespace var namespace
    VStack {
        Spacer()
        BottomInputView(session: DialogueSession(), isLoading: .constant(false),namespace: namespace, send: { _ in })
    }

        
}

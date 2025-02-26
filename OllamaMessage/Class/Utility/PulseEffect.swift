//
//  PulseEffect.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/2/26.
//

import SwiftUI

struct PulseEffect: ViewModifier {
    @State private var pulse = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pulse ? 1.2 : 1)
            .opacity(pulse ? 0.6 : 1)
            .animation(
                Animation.easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear {
                pulse.toggle()
            }
    }
}

extension View {
    func pulse() -> some View {
        self.modifier(PulseEffect())
    }
}

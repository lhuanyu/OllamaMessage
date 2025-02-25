//
//  AboutView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/2/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack {
            Text("Ollama Message")
                .font(.title)
                .bold()
                .padding(.bottom)
            ///App Icon Style
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .frame(width: 120, height: 120)
                    .shadow(radius: 10)
                Image("ollama")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 4)
                    )
            }
            .padding(.bottom)
            ///Version
            Text("\(Bundle.main.appVersion) (\(Bundle.main.appBuild))")
        }
        .navigationTitle("About")
    }
}

#Preview {
    AboutView()
}

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
            Text("OMessage")
                .font(.title)
                .bold()
                .padding(.bottom)
            /// App Icon Style
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .frame(width: 120, height: 120)
                    .shadow(radius: 10)
                Image("omessage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.bottom)
            /// Version
            Text("\(Bundle.main.appVersion) (\(Bundle.main.appBuild))")
        }
        .navigationTitle("About")
    }
}

#Preview {
    AboutView()
}

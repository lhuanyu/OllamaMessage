//
//  ImageMessageView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/4/6.
//

import SwiftUI
import Kingfisher

struct ImageMessageView: View {
    
    var url: URL?
    
    var body: some View {
        KFImage(url)
            .resizable()
            .fade(duration: 0.25)
            .placeholder { p in
                ProgressView()
            }
            .cacheOriginalImage()
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    ImageMessageView()
}

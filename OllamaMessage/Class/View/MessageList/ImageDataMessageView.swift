//
//  ImageDataMessageView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/4/6.
//

import SwiftUI

struct ImageDataMessageView: View {
    
    var data: Data?
    
    var body: some View {
        if let data = data {
            Image(data: data)?
                .resizable()
                .sizeToFit()
        } else {
            EmptyView()
        }
    }
}

#Preview {
    ImageDataMessageView()
}

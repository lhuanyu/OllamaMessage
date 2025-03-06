//
//  LeadingComposerView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/17.
//

import PhotosUI
import SwiftUI

struct LeadingComposerView: View {
    @ObservedObject var session: DialogueSession
    
    @State var selectedPromt: Prompt?
    
    @State var showPromptPopover: Bool = false
    
    @State var showPhotoPicker = false
        
    @State var imageSelection: PhotosPickerItem? = nil
    
    @Binding var isLoading: Bool

    private var height: CGFloat {
        22
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                showPhotoPicker = true
            } label: {
                Image(systemName: "camera.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: height)
            }
            .disabled(!session.configuration.ollamaModelProvider.isVisionModel)
        }
        .padding(.horizontal, 8)
        .frame(maxHeight: 32)
        .photosPicker(isPresented: $showPhotoPicker, selection: $imageSelection, matching: .images)
        .onChange(of: imageSelection) { imageSelection in
            if let imageSelection {
                isLoading = true
                imageSelection.loadTransferable(type: Data.self) { result in
                    switch result {
                    case .success(let data):
                        if let data = data {
                            DispatchQueue.main.async {
                                isLoading = false
                                self.imageSelection = nil
                                withAnimation {
                                    session.inputData = data
                                }
                            }
                        }
                    case .failure:
                        break
                    }
                }
            }
        }
    }
}

extension Data {
    var imageBased64String: String {
        "data:image/png;base64,\(base64EncodedString()))"
    }
}

struct LeadingComposerView_Previews: PreviewProvider {
    static var previews: some View {
        LeadingComposerView(session: .init(), isLoading: .constant(false))
            .previewLayout(.fixed(width: 400.0, height: 100.0))
        
        LeadingComposerView(session: .init(), isLoading: .constant(false))
            .previewLayout(.fixed(width: 400.0, height: 100.0))
        
        HStack(alignment: .bottom) {
            LeadingComposerView(session: .init(), isLoading: .constant(false))
            
            Capsule()
                .stroke(.gray, lineWidth: 2)
                .frame(maxHeight: 50)
        }
        .preferredColorScheme(.dark)
        .previewLayout(.fixed(width: 400.0, height: 100.0))
        
        LeadingComposerView(session: .init(), isLoading: .constant(false))
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 400.0, height: 100.0))
    }
}

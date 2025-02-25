//
//  OllamaModelSelectionView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/2/24.
//

import Kingfisher
import SwiftUI

struct OllamaModelSelectionView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var ollamaConfiguration: OllamaConfiguration = .shared

    @Binding var selectedModelName: String?

    var body: some View {
        NavigationStack {
            List {
                if OllamaConfiguration.shared.models.isEmpty && ollamaConfiguration.isFetching {
                    ProgressView()
                }
                ForEach(OllamaConfiguration.shared.models) { model in
                    HStack {
                        KFImage(model.name.ollamaModelProvider.iconURL)
                            .resizable()
                            .frame(width: 30, height: 30)
                            .scaledToFit()
                        Text(model.name)
                        Spacer()
                        if model.name.ollamaModelProvider.isVisionModel {
                            Image(systemName: "eye")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedModelName = model.name
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            #if os(macOS)
            .frame(minHeight: 300)
            #endif
            .task {
                await OllamaConfiguration.shared.fetchModels()
            }
            .navigationTitle("Model")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Done")
                                .bold()
                        }
                    }
                    ToolbarItem(placement: .automatic) {
                        Button {
                            Task {
                                await OllamaConfiguration.shared.fetchModels()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
        }
    }
}

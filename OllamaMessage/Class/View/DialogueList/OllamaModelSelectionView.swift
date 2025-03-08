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
                Section {
                    if OllamaConfiguration.shared.models.isEmpty && ollamaConfiguration.isFetching {
                        ProgressView()
                    } else if let error = ollamaConfiguration.error {
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                    } else {
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
                                if model.name.ollamaModelProvider.isReasoningModel {
                                    Image(systemName: "brain")
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
                } footer: {
                    if !OllamaConfiguration.shared.models.isEmpty {
                        Text("Select a model to use for generating replies. Models with the eye icon are vision models and models with the brain icon are reasoning models.")
                            .font(.caption)
                    }
                }
            }
            .task {
                await OllamaConfiguration.shared.fetchModels()
            }
            .navigationTitle("Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Done")
                            .bold()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
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

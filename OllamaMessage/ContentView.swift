//
//  ContentView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/22.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DialogueData.date, ascending: false)],
        animation: .default
    )
    private var items: FetchedResults<DialogueData>

    @EnvironmentObject var configuration: AppConfiguration
    @State var dialogueSessions: [DialogueSession] = []
    @State var selectedDialogueSession: DialogueSession?

    @State var isShowSettingView = false

    @State var isReplying = false

    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            contentView()
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            isShowSettingView = true
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showModelPicker = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
        } detail: {
            ZStack {
                if let selectedDialogueSession = selectedDialogueSession {
                    MessageListView(session: selectedDialogueSession)
                        .onReceive(selectedDialogueSession.$isReplying.didSet) { isReplying in
                            self.isReplying = isReplying
                        }
                        .onReceive(selectedDialogueSession.$conversations.didSet) { conversations in
                            if conversations.isEmpty {
                                isReplying = true
                                isReplying = false
                            }
                        }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $isShowSettingView) {
            NavigationStack {
                AppSettingsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem {
                            Button {
                                isShowSettingView = false
                            } label: {
                                Text("Done")
                                    .bold()
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showModelPicker) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                OllamaModelSelectionView(selectedModelName: $selectedModelName)
            } else {
                OllamaModelSelectionView(selectedModelName: $selectedModelName)
                    .presentationDetents([.medium, .large])
            }
        }
        .onChange(of: selectedModelName) { name in
            if let name = name {
                addItem(modelName: name)
            }
        }
        .onAppear {
            dialogueSessions = items.compactMap {
                DialogueSession(rawData: $0)
            }
        }
        .task {
            if !OllamaConfiguration.shared.apiHost.isEmpty {
                await OllamaConfiguration.shared.fetchModels()
            }
        }
    }

    @ViewBuilder
    func contentView() -> some View {
        if dialogueSessions.isEmpty {
            DialogueListPlaceholderView()
        } else {
            DialogueSessionListView(
                dialogueSessions: $dialogueSessions,
                selectedDialogueSession: $selectedDialogueSession,
                isReplying: $isReplying
            ) {
                deleteItems(offsets: $0)
            } deleteDialogueHandler: {
                deleteItem($0)
            }
        }
    }

    @State private var showModelPicker = false

    @State private var selectedModelName: String?

    private func addItem(modelName: String? = nil) {
        withAnimation {
            do {
                let session = DialogueSession()
                if let modelName = modelName {
                    session.configuration.model = modelName
                }
                dialogueSessions.insert(session, at: 0)
                let newItem = DialogueData(context: viewContext)
                newItem.id = session.id
                newItem.date = session.date
                newItem.configuration = try JSONEncoder().encode(session.configuration)
                try PersistenceController.shared.save()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    selectedDialogueSession = session
                }
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            dialogueSessions.remove(atOffsets: offsets)
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try PersistenceController.shared.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItem(_ session: DialogueSession) {
        withAnimation {
            dialogueSessions.removeAll {
                $0.id == session.id
            }
            if let item = session.rawData {
                viewContext.delete(item)
            }

            do {
                try PersistenceController.shared.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

//
//  DialogueSessionListView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/17.
//

import Kingfisher
import SwiftUI
import SwiftUIX

struct DialogueSessionListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @Environment(\.verticalSizeClass) var verticalSizeClass

    private var shouldShowIcon: Bool {
        verticalSizeClass != .compact
    }

    @Binding var dialogueSessions: [DialogueSession]
    @Binding var selectedDialogueSession: DialogueSession?

    @Binding var isReplying: Bool

    var deleteHandler: (IndexSet) -> Void
    var deleteDialogueHandler: (DialogueSession) -> Void

    var body: some View {
        List(selection: $selectedDialogueSession) {
            ForEach(dialogueSessions) { session in
                DialogueSessionView(session: session)
                    .tag(session)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteDialogueHandler(session)
                            if session == selectedDialogueSession {
                                selectedDialogueSession = nil
                            }
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                        }
                    }
            }
            .onDelete { indexSet in
                deleteHandler(indexSet)
            }
        }
        .onAppear(perform: sortList)
        .listStyle(.plain)
        .navigationTitle(Text("Ollama Message"))
        .onChange(of: isReplying) { _ in
            updateList()
        }
    }

    private func secondaryTextColor(_ session: DialogueSession) -> Color {
#if targetEnvironment(macCatalyst)
        return selectedDialogueSession == session ? Color.systemGray5 : .secondary
#else
        if UIDevice.current.userInterfaceIdiom == .pad {
            return selectedDialogueSession == session ? Color.systemGray5 : .secondary
        }
        return .secondary
#endif
    }

    private func updateList() {
        withAnimation {
            if selectedDialogueSession != nil {
                let session = selectedDialogueSession
                sortList()
                selectedDialogueSession = session
            } else {
                sortList()
            }
        }
    }

    private func sortList() {
        dialogueSessions = dialogueSessions.sorted(by: {
            $0.date > $1.date
        })
    }
}

extension Date {
    var dialogueDesc: String {
        if isInYesterday {
            return String(localized: "Yesterday")
        }
        if isInToday {
            return timeString(ofStyle: .short)
        }
        return dateString(ofStyle: .short)
    }
}

import Combine

extension Published.Publisher {
    var didSet: AnyPublisher<Value, Never> {
        // Any better ideas on how to get the didSet semantics?
        // This works, but I'm not sure if it's ideal.
        receive(on: RunLoop.main).eraseToAnyPublisher()
    }
}

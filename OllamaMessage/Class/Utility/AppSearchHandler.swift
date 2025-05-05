//
//  AppSearchHandler.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/5/05.
//

import CoreData
import CoreSpotlight
import Foundation
import MobileCoreServices
import SwiftUI
import UIKit

class AppSearchHandler: NSObject, @unchecked Sendable {

    static let shared = AppSearchHandler()

    // Index app content to make it visible in Spotlight search
    func indexAppContent() {
        // Create search items related to keywords
        let keywords = ["ollama", "chatgpt", "ai"]
        var searchableItems: [CSSearchableItem] = []

        for (index, keyword) in keywords.enumerated() {
            // Create attribute set
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.title = keyword.capitalized
            attributeSet.contentDescription = "AI conversations related to \(keyword)"

            // Create searchable item
            let searchableItem = CSSearchableItem(
                uniqueIdentifier: "keyword-\(index)",
                domainIdentifier: Bundle.main.bundleIdentifier,
                attributeSet: attributeSet
            )

            searchableItems.append(searchableItem)
        }

        // Get dialogue sessions and index them
        let dialogueSessions = fetchDialogueSessions()
        for session in dialogueSessions {
            if let searchableItem = createSearchableItemForSession(session) {
                searchableItems.append(searchableItem)
            }
        }

        // Index these items
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            if let error = error {
                print("Indexing error: \(error.localizedDescription)")
            } else {
                print("Successfully indexed keywords and conversations")
            }
        }
    }

    // Index a specific dialogue session
    func indexDialogueSession(_ session: DialogueSession) {
        guard let searchableItem = createSearchableItemForSession(session) else {
            return
        }

        // Index the session
        CSSearchableIndex.default().indexSearchableItems([searchableItem]) { error in
            if let error = error {
                print("Session indexing error: \(error.localizedDescription)")
            } else {
                print("Successfully indexed session: \(session.title ?? "Untitled")")
            }
        }
    }

    // Create a searchable item for a dialogue session
    private func createSearchableItemForSession(_ session: DialogueSession) -> CSSearchableItem? {
        // Skip if session has no conversations
        guard !session.conversations.isEmpty else {
            return nil
        }

        // Create attribute set
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)

        // Set title (use default if not available)
        let sessionTitle = session.title ?? "Untitled Conversation"
        attributeSet.title = sessionTitle

        // Use the last message's content as the description
        attributeSet.contentDescription = session.lastMessage

        // Add title to searchable text
        attributeSet.displayName = sessionTitle

        // Combine title and last message content as complete searchable text
        let searchableText = "\(sessionTitle) \(session.lastMessage)"
        attributeSet.textContent = searchableText

        // Add keywords based on conversation content
        var keywords = [String]()

        // First add keywords from the title
        keywords.append(
            contentsOf: sessionTitle.components(separatedBy: .whitespacesAndNewlines)
                .filter { $0.count >= 2 })  // Allow keywords with 2 or more characters

        // Add keywords from the last message
        keywords.append(
            contentsOf: session.lastMessage.components(separatedBy: .whitespacesAndNewlines)
                .filter { $0.count >= 2 })

        for conversation in session.conversations {
            // Add keywords from input
            let inputWords = conversation.input.components(separatedBy: .whitespacesAndNewlines)
                .filter { $0.count >= 2 }  // Allow keywords with 2 or more characters
            keywords.append(contentsOf: inputWords)

            // Add keywords from reply if available
            if let reply = conversation.reply {
                let replyWords = reply.components(separatedBy: .whitespacesAndNewlines)
                    .filter { $0.count >= 2 }
                keywords.append(contentsOf: replyWords)
            }
        }

        // Limit keywords to avoid overwhelming the index
        if keywords.count > 200 {
            keywords = Array(keywords.prefix(200))
        }

        attributeSet.keywords = Array(Set(keywords))  // Remove duplicates

        // Create searchable item with session ID as unique identifier
        let searchableItem = CSSearchableItem(
            uniqueIdentifier: "session-\(session.id.uuidString)",
            domainIdentifier: Bundle.main.bundleIdentifier,
            attributeSet: attributeSet
        )

        // Set a shorter expiration period to ensure search results are always up-to-date
        searchableItem.expirationDate = Date().addingTimeInterval(60 * 60 * 24 * 30)  // 30 days

        return searchableItem
    }

    // Fetch all dialogue sessions from Core Data
    private func fetchDialogueSessions() -> [DialogueSession] {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<DialogueData> = DialogueData.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \DialogueData.date, ascending: false)
        ]

        do {
            let items = try context.fetch(fetchRequest)
            return items.compactMap { DialogueSession(rawData: $0) }
        } catch {
            print("Failed to fetch dialogue sessions: \(error)")
            return []
        }
    }

    // Remove all items from the index
    func deindexAppContent() {
        CSSearchableIndex.default().deleteAllSearchableItems { error in
            if let error = error {
                print("Index deletion error: \(error.localizedDescription)")
            }
        }
    }

    // Remove a specific session from the index
    func deindexDialogueSession(_ session: DialogueSession) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [
            "session-\(session.id.uuidString)"
        ]) { error in
            if let error = error {
                print("Session deindexing error: \(error.localizedDescription)")
            }
        }
    }
}

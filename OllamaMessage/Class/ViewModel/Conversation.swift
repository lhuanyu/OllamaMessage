//
//  Conversation.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/3.
//

import SwiftUI

enum MessageType {
    case text
    case image
    case imageData
    case error
    
    var isImage: Bool {
        self == .image || self == .imageData
    }
}

struct Conversation: Identifiable, Codable, Equatable {
    var id = UUID()
        
    var isLast: Bool = false
    
    var input: String
    
    var inputData: Data?
    
    var reply: String?
    
    var replyData: Data?
    
    var errorDesc: String?
    
    var date = Date()
    
    var preview: String {
        if let errorDesc = errorDesc {
            return errorDesc
        }
        if reply == nil || reply?.isEmpty == true {
            return inputPreview
        }
        if replyType == .image || replyType == .imageData {
            return String(localized: "[Image]")
        }
        return replyContent ?? ""
    }
    
    private var replyContent: String? {
        reply?.components(separatedBy: "</think>").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? reply
    }
    
    private var inputPreview: String {
        if inputType == .image || inputType == .imageData {
            return String(localized: "[Image]")
        }
        return input
    }
    
    var inputType: MessageType {
        if inputData != nil {
            return .imageData
        }
        if input.hasPrefix("![Image]") {
            return .image
        } else if input.hasPrefix("![ImageData]") {
            return .imageData
        }
        return .text
    }
    
    var replyType: MessageType {
        guard errorDesc == nil else {
            return .error
        }
        guard let reply = reply else {
            return .error
        }
        if reply.hasPrefix("![Image]") {
            return .image
        } else if reply.hasPrefix("![ImageData]") {
            return .imageData
        }
        return .text
    }
    
    var replyImageURL: URL? {
        guard replyType == .image else {
            return nil
        }
        guard let reply = reply else {
            return nil
        }
        let path = String(reply.deletingPrefix("![Image](").dropLast())
        return URL(string: path)
    }
    
    var replyImageData: Data? {
        guard replyType == .imageData else {
            return nil
        }
        if let replyData = replyData {
            return replyData
        }
        guard let reply = reply else {
            return nil
        }
        let base64 = String(reply.deletingPrefix("![ImageData](data:image/png;base64,").dropLast())
        return Data(base64Encoded: base64)
    }
}

extension String {
    var base64ImageData: Data? {
        guard hasPrefix("![ImageData](data:image/png;base64,") else {
            return nil
        }
        let base64 = String(deletingPrefix("![ImageData](data:image/png;base64,").dropLast())
        return Data(base64Encoded: base64)
    }
}

extension Conversation {
    
    static var samples: [Conversation] {
        [
            Conversation(
                input: "How can I implement dark mode in SwiftUI?",
                reply: "To implement dark mode in SwiftUI:\n1. Use Color assets in Asset catalog\n2. Set up adaptive colors\n3. Use preferredColorScheme modifier\n4. Test both appearances in preview",
                date: Date(timeIntervalSinceNow: -604800) // 1 week ago
            ),
            Conversation(
                input: "What's the best way to handle async/await in SwiftUI?",
                reply: "For async/await in SwiftUI:\n- Use Task viewModifier for async operations\n- Implement proper error handling\n- Cancel tasks when view disappears\n- Consider using AsyncImage for image loading",
                date: Date(timeIntervalSinceNow: -432000) // 5 days ago
            ),
            Conversation(
                input: "Explain MVVM architecture in SwiftUI",
                reply: "MVVM in SwiftUI:\n- Model: Data and business logic\n- View: UI elements and layout\n- ViewModel: @Published properties and business logic\n- Use ObservableObject protocol for data binding",
                date: Date(timeIntervalSinceNow: -259200) // 3 days ago
            ),
            Conversation(
                input: "How do I use Core Data with SwiftUI?",
                reply: "Core Data integration steps:\n1. Create .xcdatamodeld file\n2. Set up persistent container\n3. Use @Environment(.\\.managedObjectContext)\n4. Create FetchRequest for data\n5. Implement CRUD operations",
                date: Date(timeIntervalSinceNow: -172800) // 2 days ago
            ),
            Conversation(
                input: "Best practices for SwiftUI navigation?",
                reply: "Navigation best practices:\n- Use NavigationStack for iOS 16+\n- Implement deep linking\n- Handle navigation state in ViewModel\n- Consider programmatic navigation\n- Use type-safe navigation paths",
                date: Date(timeIntervalSinceNow: -86400) // 1 day ago
            ),
            Conversation(
                input: "How to implement custom animations?",
                reply: "Custom animations in SwiftUI:\n1. Use withAnimation block\n2. Create custom timing curves\n3. Implement matching geometry effect\n4. Use transition modifiers\n5. Consider spring animations",
                date: Date(timeIntervalSinceNow: -43200) // 12 hours ago
            ),
            Conversation(
                input: "Explain dependency injection in Swift",
                reply: "Dependency injection:\n- Use protocols for abstractions\n- Inject dependencies through init\n- Consider using property wrappers\n- Make testing easier\n- Avoid singleton abuse",
                date: Date(timeIntervalSinceNow: -21600) // 6 hours ago
            ),
            Conversation(
                input: "How to handle user authentication?",
                reply: "Authentication implementation:\n1. Create AuthManager class\n2. Use Keychain for secure storage\n3. Implement proper logout\n4. Handle token refresh\n5. Show loading states",
                date: Date(timeIntervalSinceNow: -7200) // 2 hours ago
            ),
            Conversation(
                input: "Best way to handle API calls?",
                reply: "API handling best practices:\n- Create dedicated API service\n- Use async/await\n- Implement proper error handling\n- Add request interceptors\n- Cache responses when appropriate",
                date: Date(timeIntervalSinceNow: -3600) // 1 hour ago
            ),
            Conversation(
                input: "How to implement image caching?",
                reply: "Image caching implementation:\n1. Use NSCache for memory cache\n2. Implement disk caching\n3. Create async image loading\n4. Handle cache invalidation\n5. Consider using SDWebImage",
                date: Date()
            )
        ]
    }
}

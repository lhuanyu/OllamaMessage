//
//  OllamaService.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/2/15.
//

import SwiftUI

final class OllamaService: @unchecked Sendable {
    init(configuration: DialogueSession.Configuration) {
        self.configuration = configuration
    }
    
    var configuration: DialogueSession.Configuration
        
    var messages = [Message]()
    
    func createTitle() async throws -> String? {
        guard !AppConfiguration.shared.suggestionsModel.isEmpty else {
            return nil
        }
        
        guard !messages.isEmpty else {
            return nil
        }
        
        let chatHistory = messages.reduce("") { $0 + "[\($1.role)]:\($1.content)" + "\n" }
        let prompt = """
        There is a conversation between a user and an assistant. The conversation is as follows: \n\(chatHistory)\n
        - Generate a title which summarizes the conversation above.
        - The title should use the same language of the locale '\(Locale.current)'. 
        - The title should be short and unique.
        - Return the title only, do not use markdown syntax, do not use quotes.
        """

        let title = try await chat(prompt, model: AppConfiguration.shared.suggestionsModel, includingHistory: false)
        print("Title: \(title)")
        return title
    }
        
    private var suggestionsCount: Int {
        return 3
    }
    
    func createSuggestions() async throws -> [String] {
        guard !AppConfiguration.shared.suggestionsModel.isEmpty else {
            return []
        }
        let chatHistory = messages.reduce("") { $0 + "[\($1.role)]:\($1.content)" + "\n" }
        let prompt: String
        
        if messages.isEmpty {
            prompt = """
            - Generate \(suggestionsCount) suggestions for the first question user might ask.
            - The suggestions should cover a wide range of topics and be interesting.
            - The suggestions should use the same language of the locale '\(Locale.current)'.
            - The suggestions should be short and unique.
            - Return the suggestions only in an array format, such as: ["suggestion1", "suggestion2", "suggestion3"], do not use markdown syntax.
            - You must return \(suggestionsCount) suggestions.
            """
        } else {
            prompt = """
            There is a conversation between a user and an assistant. The conversation is as follows: \n\(chatHistory)\n
            - Generate \(suggestionsCount) suggestions for the next quetion user might ask based on the conversation above.
            - The suggestions should use the same language of the locale '\(Locale.current)'. 
            - The suggestions should be short and unique.
            - Return the suggestions only in an array format, such as: ["suggestion1", "suggestion2", "suggestion3"], do not use markdown syntax. 
            - You must return \(suggestionsCount) suggestions.
            """
        }

        let suggestions = try await chat(prompt, model: AppConfiguration.shared.suggestionsModel, includingHistory: false)
        print("Suggestions: \(suggestions)")
        return suggestions.normalizedPrompts
    }
    
    func appendNewMessage(input: String, reply: String) {
        messages.append(.init(role: "user", content: input))
        messages.append(.init(role: "assistant", content: reply))
    }
    
    func sendMessage(_ input: String, data: Data? = nil) async throws -> AsyncThrowingStream<String, Error> {
        do {
            return try await chatStream(input, data: data)
        } catch {
            appendNewMessage(input: input, reply: "")
            throw error
        }
    }
    
    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    private var streamingTask: Task<Void, Never>?
    private var currentURLSessionTask: URLSessionTask?

    func chatStream(_ input: String, data: Data? = nil) async throws -> AsyncThrowingStream<String, Error> {
        do {
            let chatRequest = OllamaChatRequest(
                model: configuration.model,
                messages: messages + [
                    Message(
                        role: "user",
                        content: input,
                        images: data != nil ? [data!.base64EncodedString()] : nil
                    )
                ],
                system: configuration.systemPrompt,
                keep_alive: OllamaConfiguration.shared.keepAlive,
                options: .init(
                    temperature: configuration.temperature,
                    num_ctx: configuration.numCtx
                )
            )
            
            guard let url = URL(string: AppConfiguration.shared.ollamaAPIHost + "/api/chat") else {
                throw URLError(.badURL)
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            for header in OllamaConfiguration.shared.headerItems {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
            
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(chatRequest)
            request.timeoutInterval = 60 * 5
            
            let (bytes, _) = try await URLSession.shared.bytes(for: request)

            currentURLSessionTask = bytes.task
            
            if isCancellingStream {
                print("Stopping streaming...")
                currentURLSessionTask?.cancel()
                currentURLSessionTask = nil
                isCancellingStream = false
                print("Streaming stopped")
                return AsyncThrowingStream<String, Error> { continuation in
                    continuation.finish()
                }
            }
            
            return AsyncThrowingStream<String, Error> { continuation in
                streamingTask = Task(priority: .userInitiated) {
                    do {
                        var responseContent = ""
                        for try await line in bytes.lines {
                            if Task.isCancelled {
                                print("Streaming cancelled")
                                continuation.finish()
                                return
                            }
                            
                            responseContent += line
                            print("Received chunk: \(line)")
                            
                            if let response = try? decoder.decode(OllamaResponse.self, from: Data(line.utf8)) {
                                continuation.yield(response.message.content)
                            } else if let finalResponse = try? decoder.decode(OllamaFinalResponse.self, from: Data(line.utf8)) {
                                print("Final response: \(finalResponse)")
                            } else {
                                continuation.finish(throwing: URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: line]))
                            }
                        }
                        appendNewMessage(input: input, reply: responseContent)
                        continuation.finish()
                    } catch {
                        let error = error as NSError
                        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                            print("Streaming cancelled")
                            continuation.finish()
                        } else {
                            continuation.finish(throwing: error)
                        }
                    }
                }
            }
        } catch {
            print("Error: \(error)")
            throw error
        }
    }
    
    private var isCancellingStream = false
    
    func stopStreaming() {
        isCancellingStream = true
        if currentURLSessionTask == nil {
            return
        }
        print("Stopping streaming...")
        currentURLSessionTask?.cancel()
        streamingTask?.cancel()
        streamingTask = nil
        currentURLSessionTask = nil
        isCancellingStream = false
        print("Streaming stopped.")
    }
    
    /// no stream
    func chat(_ input: String, model: String? = nil, messages: [Message] = [], includingHistory: Bool = false) async throws -> String {
        do {
            let chatRequest = OllamaChatRequest(
                model: model ?? configuration.model,
                messages: includingHistory ? messages + [Message(role: "user", content: input)] : [Message(role: "user", content: input)],
                stream: false,
                keep_alive: OllamaConfiguration.shared.keepAlive,
                options: .init(
                    temperature: configuration.temperature,
                    num_ctx: 4096
                )
            )
            
            guard let url = URL(string: AppConfiguration.shared.ollamaAPIHost + "/api/chat") else {
                throw URLError(.badURL)
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            for header in OllamaConfiguration.shared.headerItems {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
            
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(chatRequest)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let response = try decoder.decode(OllamaResponse.self, from: data)
            return response.message.content
        } catch {
            print("Error: \(error)")
            throw error
        }
    }
    
    func removeAllMessages() {
        messages.removeAll()
    }
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
    
    var normalizedPrompts: [String] {
        /// Use regex to extract suggestions from the ["Compare the prices", "Analyze the market trends", "Suggest budget alternatives"]
        let pattern = #""([^"]*)""#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: utf16.count))
        var result = [String]()
        for match in matches {
            if let range = Range(match.range(at: 1), in: self) {
                result.append(String(self[range]))
            }
        }
        return result
    }
}

//
//  AIProvider.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/2/18.
//

import Foundation

enum OllamaModelProvider: String {
    case qwen
    case qwq
    case qwen3
    case deepseek_r1 = "deepseek-r1"
    case deepseek
    case llama
    case llamaVision
    case llava
    case mistral
    case phi
    case phi4_resoning
    case gemma
    case gemma3
    case minicpm_v = "minicpm-v"
    case moondream
    case bakllava
    case unknown

    var iconURL: URL? {
        let styleName = UITraitCollection.current.userInterfaceStyle.styleName
        switch self {
        case .phi:
            return URL(string: "https://registry.npmmirror.com/@lobehub/icons-static-png/latest/files/\(styleName)/microsoft-color.png")
        case .llama, .llamaVision:
            return URL(string: "https://registry.npmmirror.com/@lobehub/icons-static-png/latest/files/\(styleName)/meta-color.png")
        case .deepseek, .deepseek_r1:
            return URL(string: "https://registry.npmmirror.com/@lobehub/icons-static-png/latest/files/\(styleName)/deepseek-color.png")
        case .qwen, .qwq, .qwen3:
            return URL(string: "https://registry.npmmirror.com/@lobehub/icons-static-png/latest/files/\(styleName)/qwen-color.png")
        case .gemma, .mistral, .llava:
            return URL(string: "https://registry.npmmirror.com/@lobehub/icons-static-png/latest/files/\(styleName)/\(rawValue)-color.png")
        case .gemma3:
            return URL(string: "https://registry.npmmirror.com/@lobehub/icons-static-png/latest/files/\(styleName)/gemma-color.png")
        default:
            return URL(string: "https://registry.npmmirror.com/@lobehub/icons-static-png/latest/files/\(styleName)/ollama.png")
        }
    }

    var isVisionModel: Bool {
        switch self {
        case .llamaVision, .llava, .moondream, .bakllava, .minicpm_v, .gemma3:
            return true
        default:
            return false
        }
    }

    var isReasoningModel: Bool {
        switch self {
        case .qwq, .deepseek_r1, .qwen3, .phi4_resoning:
            return true
        default:
            return false
        }
    }
}

import UIKit

extension UIUserInterfaceStyle {
    var styleName: String {
        return self == .dark ? "dark" : "light"
    }
}

extension String {
    var ollamaModelProvider: OllamaModelProvider {
        if let model = OllamaModelProvider(rawValue: self.components(separatedBy: ":").first ?? self) {
            return model
        } else if self.hasPrefix("qwen3") {
            return .qwen3
        } else if self.hasPrefix("qwen") {
            return .qwen
        } else if self.hasPrefix("qwq") {
            return .qwq
        } else if self.hasPrefix("deepseek") {
            return .deepseek
        } else if self.hasPrefix("llama") {
            return self.contains("vision") ? .llamaVision : .llama
        } else if self.hasPrefix("mistral") {
            return .mistral
        } else if self.hasPrefix("phi4") && self.hasSuffix("reasoning") {
            return .phi4_resoning
        } else if self.hasPrefix("phi") {
            return .phi
        } else if self.hasPrefix("gemma3") {
            return .gemma3
        } else if self.hasPrefix("gemma") {
            return .gemma
        } else if self.hasPrefix("llava") {
            return .llava
        } else {
            return .unknown
        }
    }
}

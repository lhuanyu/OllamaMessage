//
//  KeyboardPublisher.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2023/3/20.
//

import Combine
import UIKit

/// Publisher to read keyboard changes.
public protocol KeyboardReadable {
    var keyboardWillChangePublisher: AnyPublisher<Bool, Never> { get }
    var keyboardDidChangePublisher: AnyPublisher<Bool, Never> { get }
    var keyboardHeight: AnyPublisher<CGFloat, Never> { get }
}

public extension KeyboardReadable {
    var keyboardWillChangePublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }

    var keyboardDidChangePublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardDidShowNotification)
                .map { _ in true },
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardDidHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }

    var keyboardHeight: AnyPublisher<CGFloat, Never> {
        NotificationCenter
            .default
            .publisher(for: UIResponder.keyboardDidShowNotification)
            .map { notification in
                if let keyboardFrame: NSValue = notification
                    .userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
                {
                    let keyboardRectangle = keyboardFrame.cgRectValue
                    let keyboardHeight = keyboardRectangle.height
                    return keyboardHeight
                } else {
                    return 0
                }
            }
            .eraseToAnyPublisher()
    }
}

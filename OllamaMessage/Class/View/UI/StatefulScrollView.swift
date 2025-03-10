//
//  StateScrollView.swift
//  OllamaMessage
//
//  Created by LuoHuanyu on 2025/3/10.
//

import SwiftUI
import SwiftUIIntrospect

enum UIXScrollPhase {
    case idle
    case tracking
    case decelerating
    case interacting
    case animating
    
    var isScrolling: Bool {
        self != .idle
    }
}

struct ScrollPhasePreferenceKey: PreferenceKey {
    static let defaultValue: UIXScrollPhase = .idle
    
    static func reduce(value: inout UIXScrollPhase, nextValue: () -> UIXScrollPhase) {
        value = nextValue()
    }
}

@MainActor
class ScrollViewCoordinator: NSObject, ObservableObject, UIScrollViewDelegate {
    @Published var scrollPhase: UIXScrollPhase = .idle
    
    var uiScrollView: UIScrollView?
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollPhase = scrollView.isTracking ? .tracking : .idle
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging && !scrollView.isDecelerating {
            scrollPhase = .interacting
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollPhase = decelerate ? .decelerating : .idle
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollPhase = .idle
    }
}

struct StatefulScrollView<Content: View>: View {
    @StateObject var coordinator = ScrollViewCoordinator()
    
    let content: () -> Content
    
    var body: some View {
        if #available(iOS 18.0, *) {
            ScrollView {
                content()
            }
            .scrollClipDisabled()
            .onScrollPhaseChange { _, newPhase in
                coordinator.scrollPhase = newPhase.xScrollPhase
            }
            .preference(key: ScrollPhasePreferenceKey.self, value: coordinator.scrollPhase)
        } else {
            ScrollView {
                content()
            }
            .introspect(.scrollView, on: .iOS(.v16, .v17, .v18)) { scrollView in
                scrollView.delegate = coordinator
                scrollView.clipsToBounds = false
                coordinator.uiScrollView = scrollView
            }
            .preference(key: ScrollPhasePreferenceKey.self, value: coordinator.scrollPhase)
        }
    }
}

@available(iOS 18.0, *)
extension ScrollPhase {
    var xScrollPhase: UIXScrollPhase {
        switch self {
        case .idle:
            return .idle
        case .tracking:
            return .tracking
        case .decelerating:
            return .decelerating
        case .interacting:
            return .interacting
        case .animating:
            return .animating
        @unknown default:
            fatalError()
        }
    }
}

#Preview {
    StatefulScrollView {
        ForEach(0 ..< 100) { index in
            Text("Item \(index)")
                .frame(maxWidth: .infinity)
                .padding()
        }
    }
}

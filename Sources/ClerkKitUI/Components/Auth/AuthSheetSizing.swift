//
//  AuthSheetSizing.swift
//  Clerk
//
//  chekusu fork: in a sheet, AuthView is as tall as the screen it shows, not the large detent.
//

#if os(iOS) || os(macOS)

import SwiftUI

@MainActor
@Observable
final class AuthSheetSizing {
  /// The height of the screen on top: its scroll content plus the navigation bar.
  var height: CGFloat?
}

private struct ContentMetrics: Equatable {
  var contentHeight: CGFloat
  var topInset: CGFloat
}

private struct AuthSheetContentSizingModifier: ViewModifier {
  @Environment(AuthSheetSizing.self) private var sizing: AuthSheetSizing?
  @State private var height: CGFloat?
  @State private var isOnTop = false
  @State private var maxTopInset: CGFloat = 0

  func body(content: Content) -> some View {
    #if os(iOS)
    if #available(iOS 18.0, *) {
      content
        .onScrollGeometryChange(for: ContentMetrics.self) { geometry in
          ContentMetrics(
            contentHeight: geometry.contentSize.height.rounded(.up),
            topInset: geometry.contentInsets.top.rounded(.up)
          )
        } action: { _, new in
          // The top inset flips between 0 and the navigation bar's height as the sheet moves, so following it would
          // resize the sheet again and again. The largest inset seen only grows, so the height settles.
          let topInset = max(maxTopInset, new.topInset)
          let newHeight = new.contentHeight + topInset
          maxTopInset = topInset
          guard height.map({ abs($0 - newHeight) >= 1 }) ?? true else { return }
          height = newHeight
          report()
        }
        // During a push or pop both screens are on screen and both see the sheet resize; only the one on top may
        // set the height, or the two keep resizing the sheet for each other.
        .onAppear {
          isOnTop = true
          report()
        }
        .onDisappear { isOnTop = false }
    } else {
      content
    }
    #else
    content
    #endif
  }

  private func report() {
    guard isOnTop, let sizing, let height else { return }
    if let current = sizing.height, abs(current - height) < 1 { return }
    sizing.height = height
  }
}

private struct AuthSheetDetentsModifier: ViewModifier {
  let sizing: AuthSheetSizing

  func body(content: Content) -> some View {
    #if os(iOS)
    // The system adds the bottom safe area to a custom detent's height.
    content.presentationDetents(sizing.height.map { [.height(max(1, $0))] } ?? [.large])
    #else
    content
    #endif
  }
}

extension View {
  /// Reports the height of this auth screen's scroll content to the sheet.
  func authSheetContentSizing() -> some View {
    modifier(AuthSheetContentSizingModifier())
  }

  /// Sizes the enclosing sheet to the auth screen on top. Outside a sheet it has no effect.
  func authSheetDetents(_ sizing: AuthSheetSizing) -> some View {
    modifier(AuthSheetDetentsModifier(sizing: sizing))
  }
}

#endif

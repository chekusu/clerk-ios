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

private struct AuthSheetContentSizingModifier: ViewModifier {
  @Environment(AuthSheetSizing.self) private var sizing: AuthSheetSizing?
  @State private var height: CGFloat?

  func body(content: Content) -> some View {
    #if os(iOS)
    if #available(iOS 18.0, *) {
      content
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
          (geometry.contentSize.height + geometry.contentInsets.top).rounded(.up)
        } action: { _, newHeight in
          height = newHeight
          sizing?.height = newHeight
        }
        // Coming back to a screen sets the sheet to its height again.
        .onAppear {
          if let height { sizing?.height = height }
        }
    } else {
      content
    }
    #else
    content
    #endif
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

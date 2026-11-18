//
//  SecondaryButtonStyle.swift
//  Clerk
//

#if os(iOS) || os(macOS)

import SwiftUI

/// chekusu fork: the system's bordered button in the text colour (grey fill), as social and other secondary
/// buttons are in system apps.
struct SecondaryButtonStyle: PrimitiveButtonStyle {
  @Environment(\.clerkTheme) private var theme

  let config: ClerkButtonConfig

  /// The system's large size for primary actions, its regular size for small ones.
  var controlSize: ControlSize { config.size == .large ? .large : .regular }

  @ViewBuilder
  func makeBody(configuration: Configuration) -> some View {
    let button = Button(configuration)
      .tint(theme.colors.secondaryButtonForeground)
      .controlSize(controlSize)
    switch config.emphasis {
    case .none:
      button.buttonStyle(.borderless)
    case .low, .high:
      button.buttonStyle(.bordered)
    }
  }
}

extension PrimitiveButtonStyle where Self == SecondaryButtonStyle {
  static func secondary(
    config: ClerkButtonConfig = .init()
  ) -> SecondaryButtonStyle {
    .init(config: config)
  }
}

#Preview {
  @Previewable @Environment(\.clerkTheme) var theme

  struct Content: View {
    var body: some View {
      HStack(spacing: 4) {
        Text("Continue", bundle: .module)
        Image("icon-triangle-right", bundle: .module)
          .opacity(0.6)
      }
    }
  }

  return VStack(spacing: 20) {
    Button {} label: {
      Content()
    }
    .buttonStyle(
      .secondary(
        config: .init(
          emphasis: .high,
          size: .large
        )
      )
    )

    Button {} label: {
      Content()
    }
    .buttonStyle(
      .secondary(
        config: .init(
          emphasis: .high,
          size: .small
        )
      )
    )

    Button {} label: {
      Content()
    }
    .buttonStyle(
      .secondary(
        config: .init(
          emphasis: .none,
          size: .large
        )
      )
    )

    Button {} label: {
      Content()
    }
    .buttonStyle(
      .secondary(
        config: .init(
          emphasis: .none,
          size: .small
        )
      )
    )
  }
  .padding()
  .environment(\.clerkTheme, .clerk)
}

#endif

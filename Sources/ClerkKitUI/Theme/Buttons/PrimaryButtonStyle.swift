//
//  PrimaryButtonStyle.swift
//  Clerk
//

#if os(iOS) || os(macOS)

import SwiftUI

/// chekusu fork: the system's own button styles, tinted with the theme's primary colour (the app's accent by
/// default), so ClerkKitUI looks like the app it sits in.
struct PrimaryButtonStyle: PrimitiveButtonStyle {
  @Environment(\.clerkTheme) private var theme

  let config: ClerkButtonConfig

  /// The system's large size for primary actions, its regular size for small ones.
  var controlSize: ControlSize { config.size == .large ? .large : .regular }

  @ViewBuilder
  func makeBody(configuration: Configuration) -> some View {
    let button = Button(configuration)
      .tint(theme.colors.primary)
      .controlSize(controlSize)
    switch config.emphasis {
    case .high:
      button.buttonStyle(.borderedProminent)
        .foregroundStyle(theme.colors.primaryForeground)
    case .low:
      button.buttonStyle(.bordered)
    case .none:
      button.buttonStyle(.borderless)
    }
  }
}

extension PrimitiveButtonStyle where Self == PrimaryButtonStyle {
  static func primary(
    config: ClerkButtonConfig = .init()
  ) -> PrimaryButtonStyle {
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
      .primary(
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
      .primary(
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
      .primary(
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
      .primary(
        config: .init(
          emphasis: .none,
          size: .small
        )
      )
    )

    Button {} label: {
      Content()
    }
    .buttonStyle(
      .primary(
        config: .init(
          emphasis: .low,
          size: .large
        )
      )
    )

    Button {} label: {
      Content()
    }
    .buttonStyle(
      .primary(
        config: .init(
          emphasis: .low,
          size: .small
        )
      )
    )
  }
  .padding()
  .environment(\.clerkTheme, .clerk)
}

#endif

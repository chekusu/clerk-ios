//
//  SocialButton.swift
//  Clerk
//

#if os(iOS) || os(macOS)

import ClerkKit
import NukeUI
import SwiftUI

struct SocialButton: View {
  @Environment(Clerk.self) private var clerk
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.clerkTheme) private var theme

  let provider: OAuthProvider
  let transferable: Bool
  let unsafeMetadata: JSON?
  let showsTitle: Bool
  var onStart: (() -> Void)?
  var action: (() async -> Void)?
  var result: Result<Void, Error>?
  var onSuccess: ((TransferFlowResult) -> Void)?
  var onError: ((Error) -> Void)?
  var onCancel: (() -> Void)?

  // chekusu fork: one provider per row, always "Continue with {name}". The logo sits in a fixed square that the
  // spinner takes over while signing in, so the button never changes size. No disc or ring around the logo.
  static let iconSize: CGFloat = 20

  private func providerLabel(isRunning: Bool) -> some View {
    HStack(spacing: 10) {
      ZStack {
        LazyImage(url: provider.iconImageUrl(colorScheme: colorScheme)) { state in
          if let image = state.image {
            ProviderIconView(provider: provider, image: image, foregroundColor: labelColor)
          }
        }
        .opacity(isRunning ? 0 : 1)
        if isRunning {
          ProgressView()
            .controlSize(.small)
            .tint(labelColor)
        }
      }
      .frame(width: Self.iconSize, height: Self.iconSize)

      Text("Continue with \(provider.name)", bundle: .module)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .font(theme.fonts.body.weight(.semibold))
    }
    .foregroundStyle(labelColor)
    .frame(maxWidth: .infinity)
  }

  /// Apple's button is filled in the text colour (black on light, white on dark), per Apple's guidelines.
  private var isApple: Bool { provider == .apple }

  private var labelColor: Color {
    isApple ? (colorScheme == .dark ? .black : .white) : theme.colors.secondaryButtonForeground
  }

  init(
    provider: OAuthProvider,
    transferable: Bool = true,
    unsafeMetadata: JSON? = nil,
    showsTitle: Bool = true
  ) {
    self.provider = provider
    self.transferable = transferable
    self.unsafeMetadata = unsafeMetadata
    self.showsTitle = showsTitle
  }

  init(
    provider: OAuthProvider,
    transferable: Bool = true,
    unsafeMetadata: JSON? = nil,
    showsTitle: Bool = true,
    action: (() async -> Void)? = nil
  ) {
    self.provider = provider
    self.transferable = transferable
    self.unsafeMetadata = unsafeMetadata
    self.showsTitle = showsTitle
    self.action = action
  }

  init(
    provider: OAuthProvider,
    transferable: Bool = true,
    unsafeMetadata: JSON? = nil,
    showsTitle: Bool = true,
    onStart: (() -> Void)? = nil,
    onSuccess: ((TransferFlowResult) -> Void)? = nil,
    onError: ((Error) -> Void)? = nil,
    onCancel: (() -> Void)? = nil
  ) {
    self.provider = provider
    self.transferable = transferable
    self.unsafeMetadata = unsafeMetadata
    self.showsTitle = showsTitle
    self.onStart = onStart
    self.onSuccess = onSuccess
    self.onError = onError
    self.onCancel = onCancel
  }

  var body: some View {
    AsyncButton {
      do {
        onStart?()
        if let action {
          await action()
        } else {
          try await defaultAction()
        }
      } catch {
        if error.isUserCancelledError {
          onCancel?()
          return
        } else {
          onError?(error)
        }
      }
    } label: { isRunning in
      providerLabel(isRunning: isRunning)
    }
    .modifier(SocialButtonStyleModifier(isApple: isApple))
    .accessibilityLabel(Text("Continue with \(provider.name)", bundle: .module))
    .accessibilityIdentifier(ClerkAccessibilityIdentifiers.Auth.socialProviderButton(strategy: provider.strategy))
  }
}

private struct SocialButtonStyleModifier: ViewModifier {
  let isApple: Bool
  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    if isApple {
      content
        .buttonStyle(.borderedProminent)
        .tint(colorScheme == .dark ? Color.white : Color.black)
        .controlSize(.large)
    } else {
      content
        .buttonStyle(.secondary())
    }
  }
}

extension SocialButton {
  func defaultAction() async throws {
    let result: TransferFlowResult = if provider == .apple {
      try await clerk.auth.signInWithApple(
        transferable: transferable,
        unsafeMetadata: unsafeMetadata
      )
    } else {
      try await clerk.auth.signInWithOAuth(
        provider: provider,
        transferable: transferable,
        unsafeMetadata: unsafeMetadata
      )
    }
    onSuccess?(result)
  }
}

#Preview {
  VStack {
    SocialButton(provider: .google)

    HStack {
      SocialButton(provider: .apple, showsTitle: false)
      SocialButton(provider: .google, showsTitle: false)
      SocialButton(provider: .slack, showsTitle: false)
    }
  }
  .padding()
  .environment(Clerk.preview())
}

#endif

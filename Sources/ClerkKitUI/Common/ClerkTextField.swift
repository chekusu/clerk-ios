//
//  ClerkTextField.swift
//  Clerk
//

#if os(iOS) || os(macOS)

import SwiftUI

struct ClerkTextField: View {
  @Environment(\.clerkTheme) private var theme
  @State private var revealText = false
  @FocusState private var focused: Field?

  enum Field {
    case regular, secure
  }

  enum FieldState {
    case `default`, error
  }

  let titleKey: LocalizedStringKey
  @Binding var text: String
  let isSecure: Bool
  let fieldState: FieldState
  let isEnabled: Bool
  let accessibilityIdentifier: String

  init(
    _ titleKey: LocalizedStringKey,
    text: Binding<String>,
    isSecure: Bool = false,
    fieldState: FieldState = .default,
    isEnabled: Bool = true,
    accessibilityIdentifier: String = ""
  ) {
    self.titleKey = titleKey
    _text = text
    self.isSecure = isSecure
    self.fieldState = fieldState
    self.isEnabled = isEnabled
    self.accessibilityIdentifier = accessibilityIdentifier
  }

  // chekusu fork: a plain system text field with its own placeholder (no floating label, no focus ring), on the
  // system fill, the size of the large buttons. An error draws a red outline.
  var body: some View {
    HStack(spacing: 8) {
      ZStack {
        TextField(text: $text) { Text(titleKey, bundle: .module) }
          .accessibilityHidden(isSecure && !revealText)
          .opacity(!isSecure || revealText ? 1 : 0)
          .focused($focused, equals: .regular)

        if isSecure {
          SecureField(text: $text) { Text(titleKey, bundle: .module) }
            .accessibilityHidden(revealText)
            .opacity(revealText ? 0 : 1)
            .focused($focused, equals: .secure)
        }
      }
      .lineLimit(1)
      .font(theme.fonts.body)
      .foregroundStyle(theme.colors.inputForeground)
      .onChange(of: revealText) { _, _ in
        if focused == .regular {
          focused = .secure
        } else if focused == .secure {
          focused = .regular
        }
      }

      if isSecure {
        Button {
          revealText.toggle()
        } label: {
          Image(systemName: revealText ? "eye" : "eye.slash")
            .contentTransition(.symbolEffect(.replace))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(
          Text(revealText ? "Hide password" : "Show password", bundle: .module)
        )
      }
    }
    .opacity(isEnabled ? 1 : 0.6)
    .padding(.horizontal, 14)
    .frame(minHeight: 50)
    .contentShape(.rect)
    .accessibilityIdentifier(accessibilityIdentifier)
    .onTapGesture {
      if isSecure {
        focused = revealText ? .regular : .secure
      } else {
        focused = .regular
      }
    }
    .disabled(!isEnabled)
    .background(
      theme.colors.input,
      in: .rect(cornerRadius: theme.design.borderRadius)
    )
    .overlay {
      if fieldState == .error {
        RoundedRectangle(cornerRadius: theme.design.borderRadius)
          .strokeBorder(theme.colors.danger, lineWidth: 1)
      }
    }
  }
}

#Preview {
  @Previewable @State var emptyEmail = ""
  @Previewable @State var filledEmail = "user@example.com"

  VStack(spacing: 20) {
    ClerkTextField("Enter your email", text: $emptyEmail)
    ClerkTextField("Enter your email", text: $filledEmail)
    ClerkTextField("Enter your password", text: $filledEmail, isSecure: true)
  }
  .padding()
}

#endif

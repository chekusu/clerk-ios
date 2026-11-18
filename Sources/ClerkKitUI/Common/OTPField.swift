//
//  OTPField.swift
//  Clerk
//

#if os(iOS) || os(macOS)

import ClerkKit
import SwiftUI

struct OTPField: View {
  @Environment(\.authFlowRequestOwnerId) private var authFlowRequestOwnerId
  @Environment(\.clerkTheme) private var theme

  @Binding var code: String
  var numberOfInputs: Int = 6
  @Binding var fieldState: FieldState
  @FocusState.Binding var isFocused: Bool
  var accessibilityIdentifier: String = ""
  var onCodeEntry: (String) async -> OTPSubmissionDisposition

  enum FieldState {
    case `default`
    case error
  }

  @State private var errorTrigger = false
  @State private var submissionTracker = OTPSubmissionTracker()
  @State private var submissionID = 0

  var body: some View {
    HStack(spacing: 4) {
      ForEach(0 ..< numberOfInputs, id: \.self) { index in
        otpFieldInput(index: index)
      }
    }
    .padding(.horizontal, 12)
    .frame(minHeight: 56)
    .background(theme.colors.input, in: .rect(cornerRadius: theme.design.borderRadius))
    .overlay {
      if fieldState == .error {
        RoundedRectangle(cornerRadius: theme.design.borderRadius)
          .strokeBorder(theme.colors.danger, lineWidth: 1)
      }
    }
    .accessibilityHidden(true)
    .phaseAnimator(
      [0, 10, -10, 10, -5, 5, 0], trigger: errorTrigger,
      content: { content, offset in
        content
          .offset(x: offset)
      },
      animation: { _ in
        .linear(duration: 0.06)
      }
    )
    .sensoryFeedback(.error, trigger: errorTrigger)
    .overlay {
      TextField("", text: $code)
        .accessibilityLabel(Text("Verification code", bundle: .module))
        .focused($isFocused)
        .textContentType(.oneTimeCode)
        #if os(iOS)
        .keyboardType(.numberPad)
        #elseif os(macOS)
        .textFieldStyle(.plain)
        #endif
        .accessibilityIdentifier(accessibilityIdentifier)
        .foregroundStyle(.clear)
        .tint(.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .onChange(of: code) { oldValue, newValue in
      let previousCode = String(oldValue.prefix(numberOfInputs))
      code = String(newValue.prefix(numberOfInputs))
      if previousCode == code { return }

      startSubmissionIfNeeded()

      if code.count == numberOfInputs {
        fieldState = .default
      } else if code.isEmpty {
        fieldState = .default
      }
    }
    .onChange(
      of: fieldState,
      { _, newValue in
        if newValue == .error {
          DispatchQueue.main.async {
            errorTrigger.toggle()
          }
        }
      }
    )
    .onAppear {
      fieldState = .default
    }
    .task(id: submissionID) {
      await submitActiveCodes()
    }
  }

  private func startSubmissionIfNeeded() {
    guard submissionTracker.codeDidChange(
      to: code,
      requiredLength: numberOfInputs
    ) else {
      return
    }

    submissionID += 1
  }

  private func submitActiveCodes() async {
    var submittedCode = submissionTracker.beginSubmission(
      for: code,
      requiredLength: numberOfInputs
    )

    while let code = submittedCode {
      guard !Task.isCancelled else {
        submissionTracker.cancelSubmission()
        return
      }

      fieldState = .default
      let disposition = await AuthFlowRequestScope.withOwner(authFlowRequestOwnerId) {
        await onCodeEntry(code)
      }

      submittedCode = submissionTracker.completeSubmission(
        currentCode: self.code,
        requiredLength: numberOfInputs,
        disposition: disposition
      )
    }
  }

  /// chekusu fork: one slot of a single system-filled field, as in the system's own code entry (Apple Account
  /// verification): a digit, or a dash while empty; the next slot is drawn in the accent colour while focused.
  @ViewBuilder
  func otpFieldInput(index: Int) -> some View {
    let isSelected = isFocused && code.count == index
    let digits = Array(code)
    Text(index < digits.count ? String(digits[index]) : "–")
      .font(theme.fonts.title2.monospacedDigit())
      .foregroundStyle(
        index < digits.count ? theme.colors.foreground : (isSelected ? theme.colors.primary : theme.colors.mutedForeground)
      )
      .frame(maxWidth: .infinity)
  }
}

#Preview {
  @Previewable @State var code = ""
  @Previewable @State var fieldState1 = OTPField.FieldState.default
  @Previewable @State var fieldState2 = OTPField.FieldState.default
  @Previewable @FocusState var isFocused: Bool

  VStack(spacing: 20) {
    OTPField(code: $code, fieldState: $fieldState1, isFocused: $isFocused) { _ in
      fieldState1 = .default
      return .stop
    }

    OTPField(code: $code, fieldState: $fieldState2, isFocused: $isFocused) { _ in
      fieldState2 = .error
      return .stop
    }
  }
  .padding()
}

#endif

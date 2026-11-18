//
//  ClerkErrorLocalization.swift
//  Clerk (chekusu fork)
//

#if os(iOS) || os(macOS)

import ClerkKit
import SwiftUI

/// The Frontend API returns its error messages in English only. For the errors people meet while signing in, show
/// ClerkKitUI's own localized text instead, keyed by the error code; any other error keeps the API's message.
enum ClerkErrorLocalization {
  static func text(for error: Error) -> Text {
    guard let apiError = error as? ClerkAPIError else {
      return Text(verbatim: error.localizedDescription)
    }
    switch apiError.code {
    case "form_password_incorrect":
      return Text("Password is incorrect. Try again, or use another method.", bundle: .module)
    case "form_code_incorrect":
      return Text("The code is incorrect. Try again.", bundle: .module)
    case "verification_expired":
      return Text("This code has expired. Request a new one.", bundle: .module)
    case "form_password_pwned":
      return Text("This password has appeared in a data breach. Use a different password.", bundle: .module)
    case "form_password_not_strong_enough":
      return Text("This password is not strong enough.", bundle: .module)
    case "form_password_length_too_short":
      if let minimum = firstNumber(in: apiError.longMessage ?? apiError.message ?? "") {
        return Text("Passwords must be \(minimum) characters or more.", bundle: .module)
      }
      return Text("This password is too short.", bundle: .module)
    case "user_locked":
      return Text("Your account is locked. Try again later.", bundle: .module)
    case "too_many_requests":
      return Text("Too many attempts. Wait a moment and try again.", bundle: .module)
    case "form_identifier_not_found":
      return Text("Couldn't find your account.", bundle: .module)
    case "form_param_format_invalid":
      return Text("Check the email address or phone number.", bundle: .module)
    default:
      return Text(verbatim: error.localizedDescription)
    }
  }

  private static func firstNumber(in message: String) -> Int? {
    let digits = message.split(whereSeparator: { !$0.isNumber }).first
    return digits.flatMap { Int($0) }
  }
}

#endif

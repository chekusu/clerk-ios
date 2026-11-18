//
//  AuthConfig.swift
//  Clerk
//

#if os(iOS) || os(macOS)

import ClerkKit

struct AuthConfig: Equatable {
  var initialIdentifier: String?

  var initialFirstName: String?

  var initialLastName: String?

  var prefilledFieldsAreLocked = false

  var persistsIdentifiers: Bool = true

  var unsafeMetadata: JSON?

  // chekusu fork: the app shows its own social sign-in buttons, so this view offers only the other ways in.
  var hidesSocialProviders = false
}

#endif

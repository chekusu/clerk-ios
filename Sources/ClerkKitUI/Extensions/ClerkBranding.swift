//
//  ClerkBranding.swift
//  Clerk (chekusu fork)
//

#if os(iOS) || os(macOS)

import ClerkKit
import SwiftUI

/// The product's own name on ClerkKitUI screens, for apps that share one Clerk instance between several products.
///
/// Set it once at launch. Every screen that would show the dashboard's application name ("Continue to {name}",
/// "to continue to {name}", biometric prompts, the update screen) shows this instead. Pair it with
/// ``SwiftUI/View/clerkAppIcon(_:)`` for the logo.
///
/// ```swift
/// ClerkBranding.appName = "MyApp"
/// ```
public enum ClerkBranding {
  @MainActor public static var appName: String?
}

extension Clerk {
  /// ``ClerkBranding/appName`` when set, else the dashboard's application name.
  @MainActor var brandedApplicationName: String? {
    if let name = ClerkBranding.appName, !name.isEmpty { return name }
    return environment?.displayConfig.applicationName
  }
}

#endif

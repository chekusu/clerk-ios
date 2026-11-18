import ClerkKit
import ClerkKitUI
import SwiftUI
import UIKit

// Launch args: -publishableKey <key> (from the CLERK_PUBLISHABLE_KEY environment of the test run; never committed)
//              -signOut YES (sign out first)
@main
struct PreviewApp: App {
  init() {
    Clerk.configure(publishableKey: UserDefaults.standard.string(forKey: "publishableKey") ?? "")
    ClerkBranding.appName = "Example"
    // UI tests: an endless animation (the dev-instance banner) keeps the app from ever going idle, so XCTest stalls.
    if UserDefaults.standard.bool(forKey: "noAnimations") { UIView.setAnimationsEnabled(false) }
  }

  var body: some Scene {
    WindowGroup { Root().environment(Clerk.shared) }
  }
}

struct Root: View {
  @Environment(Clerk.self) private var clerk
  @State private var ready = !UserDefaults.standard.bool(forKey: "signOut")

  var body: some View {
    Group {
      if !ready {
        ProgressView()
      } else if let user = clerk.user {
        VStack(spacing: 16) {
          Text("Signed in: \(user.id)").accessibilityIdentifier("signed-in")
          Button("Sign out") { Task { try? await clerk.auth.signOut() } }
        }
      } else {
        AuthView(isDismissible: false)
          .persistsIdentifiers(false)
          .clerkAppIcon(BrandIcon.image)
          .clerkAppIcon(maxHeight: 56)
      }
    }
    .task {
      guard !ready else { return }
      try? await clerk.auth.signOut()
      ready = true
    }
  }
}

@MainActor enum BrandIcon {
  static var image: Image {
    let view = RoundedRectangle(cornerRadius: 0).fill(.green.gradient).frame(width: 112, height: 112)
      .overlay(Image(systemName: "sparkles").font(.system(size: 52, weight: .semibold)).foregroundStyle(.white))
    let renderer = ImageRenderer(content: view)
    renderer.scale = 3
    return renderer.uiImage.map { Image(uiImage: $0) } ?? Image(systemName: "app")
  }
}

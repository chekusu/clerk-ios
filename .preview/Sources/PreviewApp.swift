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
        HostSignIn()
      }
    }
    .task {
      guard !ready else { return }
      try? await clerk.auth.signOut()
      ready = true
    }
  }
}

/// What a product shows itself: its social buttons, and a link that opens AuthView in a sheet for the email,
/// phone and password flows. AuthView leaves its own social buttons out there and fits the sheet to its content.
struct HostSignIn: View {
  @Environment(Clerk.self) private var clerk
  @State private var formIsOpen = false
  @State private var busy: OAuthProvider?

  var body: some View {
    VStack(spacing: 12) {
      Spacer()
      BrandIcon.image.resizable().frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      Text("Example").font(.title.bold()).padding(.bottom, 24)
      ForEach(clerk.environment?.authenticatableSocialProviders ?? [], id: \.strategy) { provider in
        Button {
          busy = provider
          Task {
            if provider == .apple {
              _ = try? await clerk.auth.signInWithApple()
            } else {
              _ = try? await clerk.auth.signInWithOAuth(provider: provider)
            }
            busy = nil
          }
        } label: {
          HStack(spacing: 8) {
            ZStack {
              Image(systemName: "person.crop.circle").opacity(busy == provider ? 0 : 1)
              if busy == provider { ProgressView().controlSize(.small) }
            }
            .frame(width: 20, height: 20)
            Text("使用 \(provider.name) 继续")
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityIdentifier("host.\(provider.strategy)")
      }
      Button("使用邮箱或手机号登录") { formIsOpen = true }
        .accessibilityIdentifier("host.email-link")
        .padding(.top, 8)
      Spacer()
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground).ignoresSafeArea())
    .sheet(isPresented: $formIsOpen) {
      AuthView()
        .hidesSocialProviders()
        .persistsIdentifiers(false)
        .clerkAppIcon(BrandIcon.image)
        .clerkAppIcon(maxHeight: 56)
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

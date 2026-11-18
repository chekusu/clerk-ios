//
//  SocialButtonGroup.swift
//  Clerk
//

#if os(iOS) || os(macOS)

import ClerkKit
import SwiftUI

struct SocialButtonGroup<Content: View>: View {
  #if os(iOS)
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  #endif

  let providers: [OAuthProvider]
  let lastUsedProvider: OAuthProvider?
  let content: (OAuthProvider, Bool, Bool) -> Content

  init(
    providers: [OAuthProvider],
    lastUsedProvider: OAuthProvider? = nil,
    @ViewBuilder content: @escaping (OAuthProvider, Bool, Bool) -> Content
  ) {
    self.providers = providers
    self.lastUsedProvider = lastUsedProvider
    self.content = content
  }

  var body: some View {
    SocialButtonLayout {
      ForEach(arrangedProviders) { provider in
        let isLastUsed = provider == lastUsedProvider
        content(provider, true, isLastUsed)
          .layoutValue(key: SocialButtonLastUsedLayoutValueKey.self, value: isLastUsed)
      }
    }
  }

  // chekusu fork: the same order in every product (Apple, GitHub, Google, X, then the rest as Clerk lists them);
  // the last-used badge still marks the one the person used.
  private var arrangedProviders: [OAuthProvider] {
    let rank: [OAuthProvider: Int] = [.apple: 0, .github: 1, .google: 2, .x: 3]
    return providers.enumerated()
      .sorted { (rank[$0.element] ?? 9, $0.offset) < (rank[$1.element] ?? 9, $1.offset) }
      .map(\.element)
  }

  private var remainingProviderCount: Int {
    if let lastUsedProvider {
      providers.filter { $0 != lastUsedProvider }.count
    } else {
      providers.count
    }
  }

  private var stacksTwoItemsInSingleColumn: Bool {
    #if os(iOS)
    SocialButtonLayoutConfiguration.stacksTwoItemsInSingleColumn(horizontalSizeClass: horizontalSizeClass)
    #else
    SocialButtonLayoutConfiguration.stacksTwoItemsInSingleColumn()
    #endif
  }

  private func showsTitle(for provider: OAuthProvider) -> Bool {
    Self.showsTitle(
      isLastUsed: provider == lastUsedProvider,
      hasLastUsedProvider: lastUsedProvider != nil,
      remainingProviderCount: remainingProviderCount,
      stacksTwoItemsInSingleColumn: stacksTwoItemsInSingleColumn
    )
  }

  static func showsTitle(
    isLastUsed: Bool,
    hasLastUsedProvider: Bool,
    remainingProviderCount: Int,
    stacksTwoItemsInSingleColumn: Bool
  ) -> Bool {
    isLastUsed ||
      remainingProviderCount == 1 ||
      (!hasLastUsedProvider && remainingProviderCount == 2 && stacksTwoItemsInSingleColumn)
  }

  static func arrangedProviders(
    providers: [OAuthProvider],
    lastUsedProvider: OAuthProvider?
  ) -> [OAuthProvider] {
    guard let lastUsedProvider, providers.contains(lastUsedProvider) else { return providers }
    return [lastUsedProvider] + providers.filter { $0 != lastUsedProvider }
  }
}

#endif

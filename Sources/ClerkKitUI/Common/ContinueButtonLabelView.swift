//
//  ContinueButtonLabelView.swift
//

#if os(iOS) || os(macOS)

import SwiftUI

struct ContinueButtonLabelView: View {
  @Environment(\.clerkTheme) private var theme
  var isActive: Bool = false

  // chekusu fork: the plain title, as system buttons have; the system spinner over it while working.
  var body: some View {
    Text("Continue", bundle: .module)
      .frame(maxWidth: .infinity)
      .overlayProgressView(isActive: isActive) {
        ProgressView()
          .tint(theme.colors.primaryForeground)
      }
  }
}

#endif

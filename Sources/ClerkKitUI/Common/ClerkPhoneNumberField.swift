//
//  ClerkPhoneNumberField.swift
//  Clerk
//

#if os(iOS) || os(macOS)

import PhoneNumberKit
import SwiftUI

extension ClerkPhoneNumberField {
  @Observable
  @MainActor
  final class PhoneNumberModel {
    private static let maxCallingCodeLength = 3

    private let utility = PhoneNumberUtility.shared
    let partialFormatter: PartialFormatter

    let defaultCountry: ClerkPhoneCountry
    var currentCountry: ClerkPhoneCountry {
      didSet {
        partialFormatter.defaultRegion = currentCountry.code
      }
    }

    init() {
      let resolvedDefaultCountry = Self.defaultCountry(using: utility) ?? utility.allCountries.first

      guard let defaultCountry = resolvedDefaultCountry else {
        preconditionFailure("PhoneNumberKit returned no supported countries")
      }

      self.defaultCountry = defaultCountry
      currentCountry = defaultCountry
      partialFormatter = .init(
        utility: utility,
        defaultRegion: defaultCountry.code,
        withPrefix: false
      )
    }

    private static func defaultCountry(using utility: PhoneNumberUtility) -> ClerkPhoneCountry? {
      [
        PhoneNumberUtility.defaultRegionCode(),
        Locale.current.region?.identifier,
        Locale.autoupdatingCurrent.region?.identifier,
        "US",
      ]
      .compactMap(\.self)
      .compactMap { ClerkPhoneCountry(for: $0, with: utility) }
      .first
    }

    var allCountriesExceptDefault: [ClerkPhoneCountry] {
      utility.allCountries.filter { country in
        country.code != defaultCountry.code
      }
    }

    func stringForCountry(_ country: ClerkPhoneCountry) -> String {
      "\(country.flag) \(country.name) \(country.prefix)"
    }

    var exampleNumber: String {
      utility.getFormattedExampleNumber(
        forCountry: currentCountry.code,
        withFormat: .national,
        withPrefix: false
      ) ?? ""
    }

    func formattedText(for text: String) -> (displayText: String, dataText: String) {
      if let phoneNumber = try? utility.parse(text, withRegion: currentCountry.code) {
        updateCurrentCountry(for: phoneNumber)
        return (
          utility.format(phoneNumber, toType: .national),
          utility.format(phoneNumber, toType: .e164)
        )
      }

      let digits = digitsAfterSelectingCallingCodeCountry(in: text)
      guard !digits.isEmpty else { return ("", "") }

      return (
        partialFormatter.formatPartial(digits),
        currentCountry.prefix + digits
      )
    }

    private func digitsAfterSelectingCallingCodeCountry(in text: String) -> String {
      let digits = text.filter(\.isWholeNumber)
      guard text.first(where: { $0 == "+" || $0.isWholeNumber }) == "+" else { return digits }

      let selectedCallingCode = currentCountry.prefix.dropFirst()
      if digits.hasPrefix(selectedCallingCode) {
        return String(digits.dropFirst(selectedCallingCode.count))
      }

      for length in 1 ... Self.maxCallingCodeLength {
        guard
          let callingCode = UInt64(digits.prefix(length)),
          let region = utility.mainCountry(forCode: callingCode),
          let country = ClerkPhoneCountry(for: region, with: utility)
        else { continue }

        currentCountry = country
        return String(digits.dropFirst(length))
      }

      return digits
    }

    private func updateCurrentCountry(for phoneNumber: PhoneNumber) {
      let countryCode = phoneNumber.regionID ?? utility.mainCountry(forCode: phoneNumber.countryCode)
      guard
        let countryCode,
        let country = ClerkPhoneCountry(for: countryCode, with: utility)
      else { return }

      currentCountry = country
    }
  }
}

struct ClerkPhoneNumberField: View {
  @Environment(\.clerkTheme) private var theme
  @State private var phoneNumberModel = PhoneNumberModel()
  @State var displayText = ""
  @FocusState private var isFocused: Bool

  enum FieldState {
    case `default`, error
  }

  let titleKey: LocalizedStringKey
  @Binding var text: String
  let fieldState: FieldState
  let isEnabled: Bool
  let accessibilityIdentifier: String

  init(
    _ titleKey: LocalizedStringKey,
    text: Binding<String>,
    fieldState: FieldState = .default,
    isEnabled: Bool = true,
    accessibilityIdentifier: String = ""
  ) {
    self.titleKey = titleKey
    _text = text
    self.fieldState = fieldState
    self.isEnabled = isEnabled
    self.accessibilityIdentifier = accessibilityIdentifier
  }

  private func textDidUpdate(text: String) {
    let formattedText = phoneNumberModel.formattedText(for: text)
    displayText = formattedText.displayText
    self.text = formattedText.dataText
  }

  var countrySelector: some View {
    Menu {
      Section {
        Button {
          phoneNumberModel.currentCountry = phoneNumberModel.defaultCountry
          textDidUpdate(text: displayText)
        } label: {
          Text(phoneNumberModel.stringForCountry(phoneNumberModel.defaultCountry))
            .lineLimit(1)
        }
      } header: {
        Text("Default", bundle: .module)
      }

      Section {
        ForEach(phoneNumberModel.allCountriesExceptDefault, id: \.code) { country in
          Button {
            phoneNumberModel.currentCountry = country
            textDidUpdate(text: displayText)
          } label: {
            Text(phoneNumberModel.stringForCountry(country))
              .lineLimit(1)
          }
        }
      } header: {
        Text("International", bundle: .module)
      }
    } label: {
      // chekusu fork: a plain menu label (flag and calling code), as in the system's own phone fields.
      HStack(spacing: 4) {
        Text(verbatim: "\(phoneNumberModel.currentCountry.flag) \(phoneNumberModel.currentCountry.prefix)")
          .font(theme.fonts.body)
          .foregroundStyle(theme.colors.foreground)
          .monospacedDigit()

        Image(systemName: "chevron.up.chevron.down")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(theme.colors.mutedForeground)
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text(verbatim: "\(phoneNumberModel.currentCountry.name), \(phoneNumberModel.currentCountry.prefix)"))
      .contentShape(.rect)
    }
    .fixedSize()
  }

  // chekusu fork: country menu, a divider and a system text field with its own placeholder, on the system fill.
  var body: some View {
    HStack(spacing: 12) {
      countrySelector

      Divider()
        .frame(height: 24)

      TextField(text: $displayText) { Text(titleKey, bundle: .module) }
        .focused($isFocused)
        .textContentType(.telephoneNumber)
        #if os(iOS)
        .keyboardType(.numberPad)
        #endif
        .lineLimit(1)
        .font(theme.fonts.body)
        .foregroundStyle(theme.colors.inputForeground)
        .onChange(of: displayText) { _, newValue in
          textDidUpdate(text: newValue)
        }
        .accessibilityIdentifier(accessibilityIdentifier)
    }
    .opacity(isEnabled ? 1 : 0.6)
    .padding(.horizontal, 14)
    .frame(minHeight: 50)
    .contentShape(.rect)
    .onTapGesture {
      isFocused = true
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
    .onAppear {
      textDidUpdate(text: text)
    }
  }
}

#Preview {
  @Previewable @State var emptyEmail = ""
  @Previewable @State var filledEmail = "5555550100"

  VStack(spacing: 20) {
    ClerkPhoneNumberField("Enter your phone number", text: $emptyEmail)
    ClerkPhoneNumberField("Enter your phone number", text: $filledEmail)
  }
  .padding()
}

#endif

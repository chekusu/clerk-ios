# This fork

A fork of [clerk/clerk-ios](https://github.com/clerk/clerk-ios) that changes only how ClerkKitUI looks and whose
name it shows. The sign-in logic, the Frontend API calls and ClerkKit are upstream's.

## What changes

- **Native look.** Buttons are the system's `borderedProminent`, `bordered` and `borderless` styles, colours are system
  colours with `Color.accentColor` as the primary, and fields are plain filled text fields with no floating label.
- **Social sign-in first.** The start screen shows the social buttons first, in the order Apple, GitHub, Google, X,
  with a link below them that opens the email or phone form. A social button's icon turns into a spinner without
  changing the button's height.
- **Product branding.** Several apps can share one Clerk instance. Set `ClerkBranding.appName` to the app's own name;
  it replaces the instance's application name on every screen ("Continue to MyApp"). Pass the app's icon with
  `.clerkAppIcon(_:)`.
- **The app's own social buttons.** `AuthView().hidesSocialProviders()` leaves the social buttons out, for an app that
  shows its own and opens AuthView from a "Sign in with email or phone" link.
- **A sheet that fits.** In a sheet, AuthView sizes the sheet to the screen it shows (iOS 18 and later) instead of the
  large detent.
- **Localized errors.** The Frontend API sends its error messages in English. Common sign-in errors are shown in the
  app's language by error code (`ClerkErrorLocalization`).

```swift
ClerkBranding.appName = "MyApp"

.sheet(isPresented: $emailSignInIsPresented) {
  AuthView()
    .hidesSocialProviders()
    .clerkAppIcon(Image("AppIcon"))
}
```

## Versions

Tags are upstream's version plus `-chekusu.N`, for example `1.7.3-chekusu.1`. Depend on one with `exact:`.

## Screenshots

`.preview` is an XcodeGen harness that takes simulator screenshots of the restyled flows. The publishable keys come
from the environment of the test run (`CLERK_PUBLISHABLE_KEY_PROD`, `CLERK_PUBLISHABLE_KEY_DEV`) and are never
committed.

## Taking upstream changes

Merge an upstream tag into `main`, resolve conflicts in favour of upstream logic and this fork's styles, build ClerkKitUI
for iOS and macOS, run the `.preview` screenshots, and tag the result.

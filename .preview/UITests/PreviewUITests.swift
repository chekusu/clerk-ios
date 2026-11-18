import XCTest

/// Screenshots of the restyled AuthView. SCHEME=light|dark only names the files: set the simulator's appearance with
/// `xcrun simctl ui <udid> appearance dark` before a dark run. Adjust freely: this harness is not shipped.
final class PreviewUITests: XCTestCase {
  let scheme = ProcessInfo.processInfo.environment["SCHEME"] ?? "light"

  /// `instance` names the environment variable holding that instance's publishable key: CLERK_PUBLISHABLE_KEY_PROD
  /// or CLERK_PUBLISHABLE_KEY_DEV, set for the test run only.
  func app(_ instance: String) -> XCUIApplication {
    let key = ProcessInfo.processInfo.environment["CLERK_PUBLISHABLE_KEY_\(instance.uppercased())"] ?? ""
    let app = XCUIApplication()
    app.launchArguments = ["-publishableKey", key, "-signOut", "YES", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_JP"]
    app.launch()
    return app
  }

  func el(_ app: XCUIApplication, _ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }

  /// Production instance: the first screen and a tapped social button.
  func testStart() throws {
    let app = app("prod")
    let github = el(app, "clerk.auth.socialProvider.oauth_github")
    XCTAssertTrue(github.waitForExistence(timeout: 20))
    sleep(3)
    shot("\(scheme)-1-start")
    let before = github.frame
    github.tap()
    usleep(400_000)
    print("HEIGHTS \(scheme): idle=\(before.height) busy=\(github.frame.height) idleY=\(before.minY) busyY=\(github.frame.minY)")
    shot("\(scheme)-2-github-busy")
    app.terminate()
  }

  /// Dev instance: sign up with a new +clerk_test address (code 424242, then the required password), sign out, then
  /// sign in again by password: wrong password, forgot password, reset code, new password.
  func testFlows() throws {
    let email = "preview\(Int(Date().timeIntervalSince1970))+clerk_test@example.com"
    let app = app("dev")
    let link = el(app, "clerk-auth-start-identifier-form-link")
    XCTAssertTrue(link.waitForExistence(timeout: 20))
    link.tap(); sleep(1)
    shot("\(scheme)-3-email-form")
    el(app, "clerk.auth.start.identifierSwitcher").tap(); sleep(1)
    shot("\(scheme)-4-phone-form")
    el(app, "clerk.auth.start.identifierSwitcher").tap(); sleep(1)
    el(app, "clerk.auth.start.identifier").tap()
    app.typeText(email)
    el(app, "clerk.auth.start.continue").tap()
    usleep(300_000)
    shot("\(scheme)-5-continue-busy")
    XCTAssertTrue(el(app, "clerk.auth.signUp.code").waitForExistence(timeout: 20)); sleep(1)
    app.typeText("424")
    shot("\(scheme)-6-code")
    app.typeText("242"); sleep(4)
    shot("\(scheme)-7-sign-up-password")
    el(app, "clerk.auth.signUp.password").tap()
    app.typeText("preview-password-\(Int.random(in: 100000...999999))-x")
    el(app, "clerk.auth.signUp.continue").tap()
    XCTAssertTrue(el(app, "signed-in").waitForExistence(timeout: 30))
    app.terminate()

    let again = self.app("dev")
    XCTAssertTrue(el(again, "clerk-auth-start-identifier-form-link").waitForExistence(timeout: 20))
    el(again, "clerk-auth-start-identifier-form-link").tap(); sleep(1)
    el(again, "clerk.auth.start.identifier").tap()
    again.typeText(email)
    el(again, "clerk.auth.start.continue").tap(); sleep(4)
    shot("\(scheme)-8-sign-in-first-factor")
    // Clerk may open on the code or the password step; reach the password step.
    if !el(again, "clerk.auth.signIn.password").exists {
      el(again, "clerk.auth.signIn.useAnotherMethod").tap(); sleep(2)
      shot("\(scheme)-9-other-methods")
      el(again, "clerk.auth.signIn.alternativeMethod.password").tap(); sleep(2)
    }
    el(again, "clerk.auth.signIn.password").tap()
    again.typeText("wrong-password-123456")
    el(again, "clerk.auth.signIn.continue").tap(); sleep(3)
    shot("\(scheme)-10-wrong-password")
    again.buttons["忘记密码？"].firstMatch.tap(); sleep(2)
    shot("\(scheme)-11-forgot-password")
  }

  func shot(_ name: String) {
    let png = XCUIScreen.main.screenshot()
    let attachment = XCTAttachment(screenshot: png)
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
    try? FileManager.default.createDirectory(atPath: "/tmp/clerk-fork-preview", withIntermediateDirectories: true)
    try? png.pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/clerk-fork-preview/\(name).png"))
  }
}

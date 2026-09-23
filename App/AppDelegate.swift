import Cocoa

/// Contains the Quick Look extension and shows help when opened manually.
final class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Support older installers that launched the app for registration.
    if ProcessInfo.processInfo.arguments.contains("--register-only") {
      NSApp.terminate(nil)
      return
    }

    let window = MainWindow()
    window.makeKeyAndOrderFront(nil)
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }
}

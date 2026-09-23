import Cocoa

/// Minimal host app. Its only job is to be launched once so that `pluginkit`
/// registers the embedded Quick Look extension.
final class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ notification: Notification) {
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

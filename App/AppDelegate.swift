import Cocoa

/// Minimal host app. Its only job is to be launched once so that `pluginkit`
/// registers the embedded Quick Look extension.
final class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ notification: Notification) {
    let window = MainWindow()
    window.makeKeyAndOrderFront(nil)
  }
}

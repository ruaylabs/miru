import Cocoa

// Entry point. No storyboard/nib, so the app delegate is wired manually —
// NSApplicationMain would otherwise never connect it.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()

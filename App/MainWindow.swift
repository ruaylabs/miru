import Cocoa

/// The app's single, tiny window: a label telling the user where to find Miru.
final class MainWindow: NSWindow {

  init() {
    super.init(
      contentRect: NSRect(x: 0, y: 0, width: 420, height: 120),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    title = "Miru"
    isReleasedWhenClosed = false
    center()

    let label = NSTextField(
      labelWithString: "Miru is installed. Press Space on any .md file in Finder.")
    label.font = .systemFont(ofSize: 13)
    label.alignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false

    let content = NSView()
    content.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: content.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: content.centerYAnchor),
    ])
    contentView = content
  }
}

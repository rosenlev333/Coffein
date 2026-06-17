import AppKit
import SwiftUI

/// Небольшое окно настроек: SwiftUI-вид внутри NSWindow через NSHostingController.
final class SettingsWindowController: NSWindowController {

    init(loginItems: LoginItemManager, prefs: Preferences) {
        let view = SettingsView(loginItems: loginItems, prefs: prefs)
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Настройки Coffein"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 420, height: 340))
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не поддерживается")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.center()
    }
}

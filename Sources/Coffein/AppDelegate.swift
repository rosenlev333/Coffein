import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let controller = CaffeinateController()
    private let loginItems = LoginItemManager()
    private let prefs = Preferences()
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("Coffein launched, creating status item")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = StatusIcon.image(active: false)
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(statusButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Coffein"
        }

        controller.onStateChange = { [weak self] active in
            self?.updateUI(active: active)
        }

        // Настройка 2: «Сразу включать режим при запуске».
        if prefs.activateOnLaunch {
            controller.start()
        } else {
            updateUI(active: false)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.stop()
    }

    // MARK: - Обновление вида

    private func updateUI(active: Bool) {
        statusItem.button?.image = StatusIcon.image(active: active)
        statusItem.button?.toolTip = active
            ? "Coffein: режим «не спать» включён"
            : "Coffein: выключен"
    }

    // MARK: - Клик по значку

    @objc private func statusButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true

        if isRightClick {
            showMenu()
        } else {
            controller.toggle()  // левый клик — мгновенное переключение
        }
    }

    /// Показывает меню по правому клику, временно прикрепив его к status item,
    /// чтобы левый клик и дальше переключал режим.
    private func showMenu() {
        let menu = buildMenu()
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let statusLine = NSMenuItem(
            title: controller.isActive ? "Coffein: ВКЛ \u{1F441}" : "Coffein: ВЫКЛ",
            action: nil, keyEquivalent: "")
        statusLine.isEnabled = false
        menu.addItem(statusLine)

        menu.addItem(.separator())

        let toggle = NSMenuItem(
            title: controller.isActive ? "Выключить режим" : "Включить режим",
            action: #selector(toggleFromMenu), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)

        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Настройки…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let login = NSMenuItem(title: "Запускать при входе", action: #selector(toggleLoginItem), keyEquivalent: "")
        login.target = self
        login.state = loginItems.isEnabled ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Выйти из Coffein", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        return menu
    }

    // MARK: - Действия меню

    @objc private func toggleFromMenu() {
        controller.toggle()
    }

    @objc private func toggleLoginItem() {
        loginItems.toggle()
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(loginItems: loginItems, prefs: prefs)
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    @objc private func quit() {
        controller.stop()
        NSApp.terminate(nil)
    }
}

import AppKit
import ServiceManagement

/// Настройка 1: «Запускать при входе» — приложение само появляется в строке меню
/// при старте компьютера. Обёртка над современным API `SMAppService.mainApp`
/// (macOS 13+). Регистрация отображается в Системные настройки → «Основные» →
/// «Объекты входа».
final class LoginItemManager {

    var status: SMAppService.Status { SMAppService.mainApp.status }

    var isEnabled: Bool { status == .enabled }

    @discardableResult
    func toggle() -> Bool {
        if status == .enabled {
            return disable()
        } else {
            return enable()
        }
    }

    @discardableResult
    func enable() -> Bool {
        do {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
            return SMAppService.mainApp.status == .enabled
        } catch {
            NSLog("Coffein: не удалось включить автозапуск: \(error)")
            // Например, .requiresApproval — отправляем пользователя в настройки.
            SMAppService.openSystemSettingsLoginItems()
            return false
        }
    }

    @discardableResult
    func disable() -> Bool {
        do {
            try SMAppService.mainApp.unregister()
            return true
        } catch {
            NSLog("Coffein: не удалось выключить автозапуск: \(error)")
            return false
        }
    }
}

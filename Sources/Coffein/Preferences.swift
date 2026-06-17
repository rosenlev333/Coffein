import Foundation

/// Настройка 2: «Сразу включать режим при запуске» — независимый флаг в UserDefaults.
final class Preferences {

    private let defaults = UserDefaults.standard
    private let activateOnLaunchKey = "activateOnLaunch"

    var activateOnLaunch: Bool {
        get { defaults.bool(forKey: activateOnLaunchKey) }  // по умолчанию false
        set { defaults.set(newValue, forKey: activateOnLaunchKey) }
    }
}

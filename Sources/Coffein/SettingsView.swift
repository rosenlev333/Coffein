import SwiftUI

struct SettingsView: View {

    let loginItems: LoginItemManager
    let prefs: Preferences

    @State private var launchAtLogin: Bool
    @State private var activateOnLaunch: Bool

    init(loginItems: LoginItemManager, prefs: Preferences) {
        self.loginItems = loginItems
        self.prefs = prefs
        _launchAtLogin = State(initialValue: loginItems.isEnabled)
        _activateOnLaunch = State(initialValue: prefs.activateOnLaunch)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {

            // Заголовок
            HStack(spacing: 12) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Coffein").font(.title2).bold()
                    Text("Не давать Mac засыпать")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Divider()

            // Настройка 1
            Toggle(isOn: $launchAtLogin) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Запускать при входе в систему")
                    Text("Coffein появляется в строке меню при старте компьютера")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .onChange(of: launchAtLogin) { newValue in
                if newValue { loginItems.enable() } else { loginItems.disable() }
                // Возвращаем тумблер к фактическому состоянию (на случай «требует подтверждения»).
                launchAtLogin = loginItems.isEnabled
            }

            // Настройка 2
            Toggle(isOn: $activateOnLaunch) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Сразу включать режим при запуске")
                    Text("После старта приложения режим «не спать» включается сам, без клика")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .onChange(of: activateOnLaunch) { newValue in
                prefs.activateOnLaunch = newValue
            }

            Divider()

            Text("Держит Mac бодрым даже при заблокированном экране (Cmd+Ctrl+Q). "
                 + "Закрытие крышки ноутбука всё равно усыпляет — это ограничение macOS. "
                 + "Запрет сна системы работает только при питании от сети.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("Версия \(coffeinVersion)")
                    .font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                Button("Выйти из Coffein") { NSApp.terminate(nil) }
            }
        }
        .padding(22)
        .frame(width: 420)
    }
}

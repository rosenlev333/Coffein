import AppKit
import Foundation
import ServiceManagement

let coffeinVersion = "1.0.0"

// MARK: - Точка входа

let arguments = CommandLine.arguments

if arguments.contains("--version") {
    print("Coffein \(coffeinVersion)")
    exit(0)
}

if arguments.contains("--self-test") {
    runSelfTest()  // выходит внутри
}

if arguments.contains("--login-test") {
    runLoginTest()  // выходит внутри
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)  // нет иконки в Dock, только строка меню
app.run()

// MARK: - Headless-проверка (без GUI)

/// Запускает caffeinate, убеждается что power-assertions появились, выключает,
/// убеждается что они снялись. Печатает PASS/FAIL и завершает процесс.
func runSelfTest() -> Never {
    print("== Coffein self-test ==")
    let controller = CaffeinateController()
    controller.start()

    guard let pid = controller.childPID else {
        print("FAIL: caffeinate не запустился")
        exit(1)
    }
    print("caffeinate запущен, pid=\(pid)")
    Thread.sleep(forTimeInterval: 1.2)

    let whileOn = shellOutput("/usr/bin/pmset", ["-g", "assertions"])
    let hasSystem = whileOn.contains("PreventUserIdleSystemSleep")
    let hasDisplay = whileOn.contains("PreventUserIdleDisplaySleep")
    let pidListed = whileOn.contains("pid \(pid)")
    print("ВКЛ: PreventUserIdleSystemSleep=\(hasSystem), PreventUserIdleDisplaySleep=\(hasDisplay), наш pid в списке=\(pidListed)")

    controller.stop()
    Thread.sleep(forTimeInterval: 1.2)

    let whileOff = shellOutput("/usr/bin/pmset", ["-g", "assertions"])
    let pidGone = !whileOff.contains("pid \(pid)")
    print("ВЫКЛ: наш pid исчез из assertions=\(pidGone)")

    // Статус автозапуска (read-only). Корректен только из установленного .app-бандла.
    print("Login item status (raw)=\(SMAppService.mainApp.status.rawValue) [0=NotRegistered 1=Enabled 2=RequiresApproval 3=NotFound]")

    if hasSystem && hasDisplay && pidListed && pidGone {
        print("RESULT: PASS")
        exit(0)
    } else {
        print("RESULT: FAIL")
        exit(1)
    }
}

/// Проверка автозапуска: регистрирует и снимает login item, печатает статусы.
/// Результат пишется и в stdout, и в файл (чтобы можно было запускать через `open --args`).
func runLoginTest() -> Never {
    var lines: [String] = []
    func emit(_ s: String) { print(s); lines.append(s) }

    let service = SMAppService.mainApp
    emit("bundle: \(Bundle.main.bundlePath)")
    emit("status before: \(service.status.rawValue)")
    do { try service.register(); emit("register: OK") }
    catch { emit("register ERROR: \(error)") }
    emit("status after register: \(service.status.rawValue)")
    do { try service.unregister(); emit("unregister: OK") }
    catch { emit("unregister ERROR: \(error)") }
    emit("status after unregister: \(service.status.rawValue)")

    let path = "/tmp/coffein_login_test.txt"
    try? lines.joined(separator: "\n").write(toFile: path, atomically: true, encoding: .utf8)
    exit(0)
}

/// Запускает процесс и возвращает его stdout+stderr как строку.
func shellOutput(_ launchPath: String, _ args: [String]) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: launchPath)
    process.arguments = args
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do {
        try process.run()
    } catch {
        return "ошибка запуска \(launchPath): \(error)"
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return String(data: data, encoding: .utf8) ?? ""
}

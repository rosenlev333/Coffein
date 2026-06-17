import Foundation

/// Ядро приложения: запускает и останавливает дочерний процесс
/// `/usr/bin/caffeinate -dimsu -w <наш PID>`.
///
/// Флаг `-w <PID>` заставляет caffeinate сам завершиться, когда наш процесс
/// исчезнет — защита от «осиротевшего» caffeinate даже при аварийном завершении
/// (SIGKILL), которое нельзя перехватить. Плюс мы явно шлём SIGTERM при выключении.
final class CaffeinateController {

    private(set) var isActive = false

    /// Вызывается при каждом изменении состояния (на главном потоке).
    var onStateChange: ((Bool) -> Void)?

    private var process: Process?

    /// PID дочернего процесса caffeinate (для self-test).
    var childPID: Int32? {
        guard let process, process.isRunning else { return nil }
        return process.processIdentifier
    }

    func start() {
        guard !isActive else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        let myPID = ProcessInfo.processInfo.processIdentifier
        process.arguments = ["-dimsu", "-w", "\(myPID)"]

        process.terminationHandler = { [weak self] _ in
            // caffeinate завершился сам (неожиданно) — синхронизируем состояние.
            DispatchQueue.main.async {
                guard let self, self.isActive else { return }
                self.isActive = false
                self.process = nil
                self.onStateChange?(false)
            }
        }

        do {
            try process.run()
            self.process = process
            isActive = true
            onStateChange?(true)
        } catch {
            NSLog("Coffein: не удалось запустить caffeinate: \(error)")
            self.process = nil
            isActive = false
            onStateChange?(false)
        }
    }

    func stop() {
        guard let process else {
            if isActive { isActive = false; onStateChange?(false) }
            return
        }
        process.terminationHandler = nil
        if process.isRunning {
            process.terminate()  // SIGTERM — caffeinate мгновенно снимает все assertions
        }
        self.process = nil
        isActive = false
        onStateChange?(false)
    }

    func toggle() {
        isActive ? stop() : start()
    }
}

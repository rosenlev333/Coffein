import AppKit

/// Значок в строке меню — глаз.
/// Открытый глаз = режим включён, закрытый глаз = выключен.
/// Используются системные SF Symbols как template-картинки: они автоматически
/// подстраиваются под светлую/тёмную тему строки меню.
enum StatusIcon {

    static func image(active: Bool) -> NSImage? {
        let symbolName = active ? "eye.fill" : "eye.half.closed.fill"
        let description = active ? "Режим включён" : "Режим выключен"
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)

        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)?
            .withSymbolConfiguration(config)
        image?.isTemplate = true
        return image
    }
}

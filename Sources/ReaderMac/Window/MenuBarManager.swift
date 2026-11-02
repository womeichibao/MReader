import AppKit

public class MenuBarManager {
    public static let shared = MenuBarManager()

    private var statusItem: NSStatusItem?

    public var onOpenFile: (() -> Void)?
    public var onToggleBossKey: (() -> Void)?
    public var onToggleBorderless: (() -> Void)?
    public var onToggleAlwaysOnTop: (() -> Void)?
    public var onOpenSettings: (() -> Void)?
    public var onToggleHideDockIcon: (() -> Void)?

    private init() {}

    public func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "book.pages", accessibilityDescription: "Reader")
            button.toolTip = "Reader 极简小说阅读器"
        }

        buildMenu()
    }

    public func buildMenu() {
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "打开电子书...", action: #selector(handleOpen), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        let bossKeyItem = NSMenuItem(title: "一键隐藏 / 显示 (老板键)", action: #selector(handleBossKey), keyEquivalent: "h")
        bossKeyItem.keyEquivalentModifierMask = [.command, .shift]
        bossKeyItem.target = self
        menu.addItem(bossKeyItem)

        let borderlessItem = NSMenuItem(title: "无边框极简模式", action: #selector(handleBorderless), keyEquivalent: "b")
        borderlessItem.state = AppSettings.shared.isBorderless ? .on : .off
        borderlessItem.target = self
        menu.addItem(borderlessItem)

        let topItem = NSMenuItem(title: "窗口置顶", action: #selector(handleAlwaysOnTop), keyEquivalent: "t")
        topItem.state = AppSettings.shared.isAlwaysOnTop ? .on : .off
        topItem.target = self
        menu.addItem(topItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "偏好设置...", action: #selector(handleSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出 Reader", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func handleOpen() {
        onOpenFile?()
    }

    @objc private func handleBossKey() {
        onToggleBossKey?()
    }

    @objc private func handleBorderless() {
        onToggleBorderless?()
        buildMenu()
    }

    @objc private func handleAlwaysOnTop() {
        onToggleAlwaysOnTop?()
        buildMenu()
    }

    @objc private func handleSettings() {
        onOpenSettings?()
    }

    @objc private func handleQuit() {
        NSApp.terminate(nil)
    }
}

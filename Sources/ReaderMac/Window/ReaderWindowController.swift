import AppKit
import SwiftUI

public class CustomReaderWindow: NSWindow {
    // 允许在无边框时成为 keyWindow，以便接收键盘快捷键
    public override var canBecomeKey: Bool {
        return true
    }

    public override var canBecomeMain: Bool {
        return true
    }

    // 支持在无边框模式下按住窗口任意空白区域拖动窗口
    public override func mouseDown(with event: NSEvent) {
        if AppSettings.shared.isBorderless {
            self.performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }

    // 滚轮快捷调节透明度 (对标原版 Ctrl/Cmd+滚轮调窗口透明度, Option/Alt+滚轮调文字透明度)
    public override func scrollWheel(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let delta = event.scrollingDeltaY

        // 1. Cmd + 滚轮 或 Ctrl + 滚轮: 调节窗口整体透明度与背景透明度
        if flags.contains(.command) || flags.contains(.control) {
            if abs(delta) > 0.1 {
                let step = delta > 0 ? 0.05 : -0.05
                var current = AppSettings.shared.windowOpacity
                current = min(max(current + step, 0.1), 1.0)
                AppSettings.shared.windowOpacity = current
                ReaderWindowController.shared.applySettings()
            }
            return
        }

        // 2. Option + 滚轮: 调节字体/文字透明度
        if flags.contains(.option) {
            if abs(delta) > 0.1 {
                let step = delta > 0 ? 0.05 : -0.05
                var current = AppSettings.shared.textOpacity
                current = min(max(current + step, 0.2), 1.0)
                AppSettings.shared.textOpacity = current
            }
            return
        }

        super.scrollWheel(with: event)
    }

    // 支持全窗口右键快捷弹出上下文菜单 (在无边框隐藏标题栏时尤其好用)
    public override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu(title: "ReaderContextMenu")

        let openItem = NSMenuItem(title: "打开电子书...", action: #selector(contextOpen), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

        let drawerItem = NSMenuItem(title: "目录抽屉", action: #selector(contextDrawer), keyEquivalent: "l")
        drawerItem.target = self
        menu.addItem(drawerItem)

        let searchItem = NSMenuItem(title: "全文搜索", action: #selector(contextSearch), keyEquivalent: "f")
        searchItem.target = self
        menu.addItem(searchItem)

        let jumpItem = NSMenuItem(title: "进度跳转", action: #selector(contextJump), keyEquivalent: "g")
        jumpItem.target = self
        menu.addItem(jumpItem)

        let bookmarkItem = NSMenuItem(title: "添加书签", action: #selector(contextBookmark), keyEquivalent: "d")
        bookmarkItem.target = self
        menu.addItem(bookmarkItem)

        menu.addItem(NSMenuItem.separator())

        let borderlessItem = NSMenuItem(title: "无边框极简模式", action: #selector(contextBorderless), keyEquivalent: "b")
        borderlessItem.state = AppSettings.shared.isBorderless ? .on : .off
        borderlessItem.target = self
        menu.addItem(borderlessItem)

        let topItem = NSMenuItem(title: "窗口始终置顶", action: #selector(contextTop), keyEquivalent: "t")
        topItem.state = AppSettings.shared.isAlwaysOnTop ? .on : .off
        topItem.target = self
        menu.addItem(topItem)

        let fullScreenItem = NSMenuItem(title: "全屏切换", action: #selector(contextFullScreen), keyEquivalent: "")
        fullScreenItem.target = self
        menu.addItem(fullScreenItem)

        let bossItem = NSMenuItem(title: "老板键瞬间隐藏", action: #selector(contextBoss), keyEquivalent: "h")
        bossItem.keyEquivalentModifierMask = [.command, .shift]
        bossItem.target = self
        menu.addItem(bossItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "偏好设置...", action: #selector(contextSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出 Reader", action: #selector(contextQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        NSMenu.popUpContextMenu(menu, with: event, for: self.contentView ?? self.visualEffectView())
    }

    private func visualEffectView() -> NSView {
        return self.contentView ?? NSView()
    }

    @objc private func contextOpen() {
        BookManager.shared.promptOpenFile()
    }

    @objc private func contextDrawer() {
        NotificationCenter.default.post(name: .readerToggleDrawer, object: nil)
    }

    @objc private func contextSearch() {
        NotificationCenter.default.post(name: .readerToggleSearch, object: nil)
    }

    @objc private func contextJump() {
        NotificationCenter.default.post(name: .readerToggleJumpPercent, object: nil)
    }

    @objc private func contextBookmark() {
        BookManager.shared.addCurrentBookmark()
    }

    @objc private func contextBorderless() {
        ReaderWindowController.shared.toggleBorderless()
    }

    @objc private func contextTop() {
        ReaderWindowController.shared.toggleAlwaysOnTop()
    }

    @objc private func contextFullScreen() {
        ReaderWindowController.shared.toggleFullScreen()
    }

    @objc private func contextBoss() {
        ReaderWindowController.shared.toggleBossKey()
    }

    @objc private func contextSettings() {
        NotificationCenter.default.post(name: .readerToggleSettings, object: nil)
    }

    @objc private func contextQuit() {
        NSApp.terminate(nil)
    }
}

public class ReaderWindowController: NSWindowController, NSWindowDelegate {
    public static let shared = ReaderWindowController()

    private var mouseExitTimer: Timer?
    private var isHiddenByBossKey: Bool = false
    private var trackingArea: NSTrackingArea?
    private let windowFrameKey = "com.reader.window_frame"

    public init() {
        let initialRect = NSRect(x: 100, y: 100, width: 720, height: 600)
        let window = CustomReaderWindow(
            contentRect: initialRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)

        window.title = "Reader"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 320, height: 200)
        window.delegate = self

        restoreWindowFrame()
        applySettings()
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func applySettings() {
        guard let window = self.window else { return }
        let settings = AppSettings.shared

        // 1. 无边框模式切换
        if settings.isBorderless {
            window.styleMask = [.borderless, .resizable]
            window.hasShadow = true
        } else {
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.hasShadow = true
        }

        // 2. 窗口置顶
        window.level = settings.isAlwaysOnTop ? .floating : .normal

        // 3. 窗口背景完全透明度与整体透明度
        window.isOpaque = false
        window.alphaValue = CGFloat(settings.windowOpacity)

        let theme = settings.currentTheme
        let bgAlpha = theme.bgAlpha * settings.backgroundOpacity
        window.backgroundColor = NSColor(
            srgbRed: theme.bgRed,
            green: theme.bgGreen,
            blue: theme.bgBlue,
            alpha: bgAlpha
        )
    }

    // 设置鼠标移入/移出跟踪区域
    public func setupTrackingArea() {
        guard let contentView = window?.contentView else { return }
        if let old = trackingArea {
            contentView.removeTrackingArea(old)
        }
        let area = NSTrackingArea(
            rect: contentView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        contentView.addTrackingArea(area)
        self.trackingArea = area
    }

    public override func mouseEntered(with event: NSEvent) {
        mouseExitTimer?.invalidate()
        mouseExitTimer = nil
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.window?.animator().alphaValue = CGFloat(AppSettings.shared.windowOpacity)
        }
    }

    public override func mouseExited(with event: NSEvent) {
        guard AppSettings.shared.autoHideOnMouseExit else { return }
        mouseExitTimer?.invalidate()
        let delay = AppSettings.shared.mouseExitDelay
        mouseExitTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                self.window?.animator().alphaValue = CGFloat(AppSettings.shared.mouseExitDimOpacity)
            }
        }
    }

    // 老板键：一键隐藏与恢复
    public func toggleBossKey() {
        guard let window = self.window else { return }
        if isHiddenByBossKey {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            isHiddenByBossKey = false
        } else {
            window.orderOut(nil)
            isHiddenByBossKey = true
        }
    }

    // 切换无边框模式
    public func toggleBorderless() {
        AppSettings.shared.isBorderless.toggle()
        applySettings()
    }

    // 切换置顶
    public func toggleAlwaysOnTop() {
        AppSettings.shared.isAlwaysOnTop.toggle()
        applySettings()
    }

    // 切换全屏
    public func toggleFullScreen() {
        window?.toggleFullScreen(nil)
    }

    // 一键重置为安全可视的默认窗口外观与尺寸
    public func resetWindowAppearance() {
        AppSettings.shared.selectedThemeId = ReadingTheme.parchment.id
        AppSettings.shared.windowOpacity = 1.0
        AppSettings.shared.backgroundOpacity = 1.0
        AppSettings.shared.textOpacity = 1.0
        AppSettings.shared.isBorderless = false
        AppSettings.shared.isAlwaysOnTop = false

        if let window = self.window {
            window.setFrame(NSRect(x: 100, y: 100, width: 720, height: 600), display: true)
            window.center()
            applySettings()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // 窗口尺寸与位置记忆
    public func windowDidMove(_ notification: Notification) {
        saveWindowFrame()
    }

    public func windowDidResize(_ notification: Notification) {
        saveWindowFrame()
    }

    private func saveWindowFrame() {
        guard let window = self.window else { return }
        // 全屏时不覆盖普通窗口 frame
        if window.styleMask.contains(.fullScreen) { return }
        let frameStr = NSStringFromRect(window.frame)
        UserDefaults.standard.set(frameStr, forKey: windowFrameKey)
    }

    private func restoreWindowFrame() {
        guard let window = self.window,
              let frameStr = UserDefaults.standard.string(forKey: windowFrameKey) else {
            window?.center()
            return
        }
        let rect = NSRectFromString(frameStr)
        if rect.width > 200 && rect.height > 150 {
            window.setFrame(rect, display: true)
        } else {
            window.center()
        }
    }
}

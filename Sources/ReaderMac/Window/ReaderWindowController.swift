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
}

public class ReaderWindowController: NSWindowController, NSWindowDelegate {
    public static let shared = ReaderWindowController()

    private var mouseExitTimer: Timer?
    private var isHiddenByBossKey: Bool = false
    private var trackingArea: NSTrackingArea?

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
        window.center()
        window.delegate = self

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
            window.hasShadow = false
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
}

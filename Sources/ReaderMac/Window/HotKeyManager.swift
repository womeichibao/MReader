import AppKit

public class HotKeyManager {
    public static let shared = HotKeyManager()

    private var localMonitor: Any?

    private init() {}

    public func startMonitoring(
        onToggleBossKey: @escaping () -> Void,
        onToggleBorderless: @escaping () -> Void,
        onToggleAlwaysOnTop: @escaping () -> Void,
        onZoomIn: @escaping () -> Void,
        onZoomOut: @escaping () -> Void,
        onToggleAutoScroll: @escaping () -> Void,
        onPreviousChapter: @escaping () -> Void,
        onNextChapter: @escaping () -> Void,
        onScrollUp: @escaping () -> Void,
        onScrollDown: @escaping () -> Void,
        onOpenChapterList: @escaping () -> Void,
        onOpenSearch: @escaping () -> Void,
        onOpenJumpPercent: @escaping () -> Void,
        onAddBookmark: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        stopMonitoring()

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let keyCode = event.keyCode
            let chars = event.charactersIgnoringModifiers ?? ""

            // 1. 老板键: Cmd+Shift+H 或 Option+H
            if (flags == [.command, .shift] && chars.lowercased() == "h") ||
               (flags == [.option] && chars.lowercased() == "h") {
                onToggleBossKey()
                return nil
            }

            // 2. F12 (keyCode 111) 或 Cmd+B: 切换无边框极简模式
            if keyCode == 111 || (flags == .command && chars.lowercased() == "b") {
                onToggleBorderless()
                return nil
            }

            // 3. Cmd+T: 窗口置顶/取消置顶
            if flags == .command && chars.lowercased() == "t" {
                onToggleAlwaysOnTop()
                return nil
            }

            // 4. Cmd+= / Cmd+-: 字体大小调节
            if flags == .command && (chars == "=" || chars == "+") {
                onZoomIn()
                return nil
            }
            if flags == .command && (chars == "-" || chars == "_") {
                onZoomOut()
                return nil
            }

            // 5. 空格键: 开始/暂停自动翻页 (无修饰键且非输入框中)
            if flags.isEmpty && keyCode == 49 { // 49 is Space
                onToggleAutoScroll()
                return nil
            }

            // 6. 翻章节: Cmd + 左/右箭头 (左 123, 右 124)
            if flags == .command && keyCode == 123 {
                onPreviousChapter()
                return nil
            }
            if flags == .command && keyCode == 124 {
                onNextChapter()
                return nil
            }

            // 7. 微调滚动/翻页: 上/下箭头 (上 126, 下 125), 左/右箭头
            if flags.isEmpty && (keyCode == 126 || keyCode == 123) {
                onScrollUp()
                return nil
            }
            if flags.isEmpty && (keyCode == 125 || keyCode == 124) {
                onScrollDown()
                return nil
            }

            // 8. 快捷唤起面板
            if flags == .command && chars.lowercased() == "l" {
                onOpenChapterList()
                return nil
            }
            if flags == .command && chars.lowercased() == "f" {
                onOpenSearch()
                return nil
            }
            if flags == .command && chars.lowercased() == "g" {
                onOpenJumpPercent()
                return nil
            }
            if flags == .command && chars.lowercased() == "d" {
                onAddBookmark()
                return nil
            }
            if flags == .command && chars == "," {
                onOpenSettings()
                return nil
            }

            return event
        }
    }

    public func stopMonitoring() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
}

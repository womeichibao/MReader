import AppKit
import SwiftUI

public class AppDelegate: NSObject, NSApplicationDelegate {
    public var windowController: ReaderWindowController?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. 设置主窗口视图
        let mainView = MainReaderView(bookManager: BookManager.shared)
        let hostingView = NSHostingView(rootView: mainView)

        let controller = ReaderWindowController.shared
        controller.window?.contentView = hostingView
        controller.setupTrackingArea()
        controller.showWindow(nil)
        self.windowController = controller

        // 2. 初始化菜单栏状态图标
        MenuBarManager.shared.onOpenFile = {
            BookManager.shared.promptOpenFile()
        }
        MenuBarManager.shared.onToggleBossKey = {
            controller.toggleBossKey()
        }
        MenuBarManager.shared.onToggleBorderless = {
            controller.toggleBorderless()
        }
        MenuBarManager.shared.onToggleAlwaysOnTop = {
            controller.toggleAlwaysOnTop()
        }
        MenuBarManager.shared.onOpenSettings = {
            NotificationCenter.default.post(name: .readerToggleSettings, object: nil)
        }
        MenuBarManager.shared.setup()

        // 3. 配置热键与快捷键监听
        HotKeyManager.shared.startMonitoring(
            onToggleBossKey: {
                controller.toggleBossKey()
            },
            onToggleBorderless: {
                controller.toggleBorderless()
            },
            onToggleAlwaysOnTop: {
                controller.toggleAlwaysOnTop()
            },
            onZoomIn: {
                AppSettings.shared.fontSize = min(AppSettings.shared.fontSize + 1, 36)
            },
            onZoomOut: {
                AppSettings.shared.fontSize = max(AppSettings.shared.fontSize - 1, 12)
            },
            onToggleAutoScroll: {
                AppSettings.shared.autoScrollEnabled.toggle()
            },
            onPreviousChapter: {
                BookManager.shared.previousChapter()
            },
            onNextChapter: {
                BookManager.shared.nextChapter()
            },
            onScrollUp: {
                NotificationCenter.default.post(name: .readerScrollStep, object: -CGFloat(AppSettings.shared.scrollStepDistance))
            },
            onScrollDown: {
                NotificationCenter.default.post(name: .readerScrollStep, object: CGFloat(AppSettings.shared.scrollStepDistance))
            },
            onOpenChapterList: {
                NotificationCenter.default.post(name: .readerToggleDrawer, object: nil)
            },
            onOpenSearch: {
                NotificationCenter.default.post(name: .readerToggleSearch, object: nil)
            },
            onOpenJumpPercent: {
                NotificationCenter.default.post(name: .readerToggleJumpPercent, object: nil)
            },
            onAddBookmark: {
                BookManager.shared.addCurrentBookmark()
            },
            onOpenSettings: {
                NotificationCenter.default.post(name: .readerToggleSettings, object: nil)
            }
        )

        // 4. 构建标准系统主菜单
        setupMainMenu()

        // 5. 自动恢复上次阅读书籍
        BookManager.shared.restoreLastBookIfAvailable()
    }

    public func application(_ application: NSApplication, openFiles filenames: [String]) {
        guard let first = filenames.first else { return }
        let url = URL(fileURLWithPath: first)
        BookManager.shared.openFile(url: url)
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // 点击红叉关闭窗口时保持后台或菜单栏常驻摸鱼
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "关于 Reader", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "隐藏 Reader", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem(NSMenuItem(title: "隐藏其他", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem(title: "全部显示", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "退出 Reader", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File Menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "文件")
        let openItem = NSMenuItem(title: "打开...", action: #selector(openFileAction), keyEquivalent: "o")
        openItem.target = self
        fileMenu.addItem(openItem)
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "关闭窗口", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // View Menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "视图")
        let borderlessItem = NSMenuItem(title: "无边框极简模式", action: #selector(toggleBorderlessAction), keyEquivalent: "b")
        borderlessItem.target = self
        viewMenu.addItem(borderlessItem)

        let topItem = NSMenuItem(title: "窗口置顶", action: #selector(toggleAlwaysOnTopAction), keyEquivalent: "t")
        topItem.target = self
        viewMenu.addItem(topItem)

        let bossItem = NSMenuItem(title: "老板键快速隐藏", action: #selector(toggleBossKeyAction), keyEquivalent: "H")
        bossItem.keyEquivalentModifierMask = [.command, .shift]
        bossItem.target = self
        viewMenu.addItem(bossItem)

        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func openFileAction() {
        BookManager.shared.promptOpenFile()
    }

    @objc private func toggleBorderlessAction() {
        ReaderWindowController.shared.toggleBorderless()
    }

    @objc private func toggleAlwaysOnTopAction() {
        ReaderWindowController.shared.toggleAlwaysOnTop()
    }

    @objc private func toggleBossKeyAction() {
        ReaderWindowController.shared.toggleBossKey()
    }
}

import SwiftUI
import UniformTypeIdentifiers

public struct MainReaderView: View {
    @ObservedObject var bookManager: BookManager
    @ObservedObject var settings: AppSettings = .shared

    @State private var showDrawer: Bool = false
    @State private var showSearch: Bool = false
    @State private var showJumpPercent: Bool = false
    @State private var showBookmarks: Bool = false
    @State private var showSettings: Bool = false

    @State private var isHoveringControls: Bool = false

    public init(bookManager: BookManager) {
        self.bookManager = bookManager
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            // 主阅读内容区
            if let book = bookManager.currentBook {
                ReaderContentView(book: book) { progress in
                    // 进度变更记录
                    ReadingHistoryManager.shared.updateProgress(
                        for: book.filePath,
                        chapterIndex: book.currentChapterIndex,
                        scrollProgress: progress
                    )
                }
            } else {
                emptyPlaceholderView
            }

            // 悬停浮动工具条（极简低调，摸鱼友好）
            floatingToolbar
                .opacity(isHoveringControls ? 1.0 : (settings.isBorderless ? 0.05 : 0.8))
                .animation(.easeInOut(duration: 0.2), value: isHoveringControls)
                .onHover { hovering in
                    isHoveringControls = hovering
                }
                .padding(12)

            // 侧边章节目录抽屉
            if showDrawer, let book = bookManager.currentBook {
                HStack(spacing: 0) {
                    Spacer()
                    ChapterDrawer(book: book, isPresented: $showDrawer) { newIndex in
                        bookManager.switchChapter(to: newIndex)
                    }
                    .transition(.move(edge: .trailing))
                }
            }
        }
        // 支持拖拽文件至窗口打开
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async {
                        bookManager.openFile(url: url)
                    }
                }
            }
            return true
        }
        // 弹窗表单
        .sheet(isPresented: $showSearch) {
            if let book = bookManager.currentBook {
                SearchPanel(book: book, isPresented: $showSearch) { targetChapterIndex in
                    bookManager.switchChapter(to: targetChapterIndex)
                }
            }
        }
        .sheet(isPresented: $showJumpPercent) {
            let current = bookManager.calculateOverallPercent()
            JumpPercentSheet(isPresented: $showJumpPercent, currentPercent: current) { percent in
                bookManager.jumpToPercent(percent)
            }
        }
        .sheet(isPresented: $showBookmarks) {
            if let book = bookManager.currentBook {
                BookmarkView(book: book, isPresented: $showBookmarks) { bookmark in
                    bookManager.switchChapter(to: bookmark.chapterIndex)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(isPresented: $showSettings)
        }
        .onReceive(NotificationCenter.default.publisher(for: .readerPrevChapter)) { _ in
            bookManager.previousChapter()
        }
        .onReceive(NotificationCenter.default.publisher(for: .readerNextChapter)) { _ in
            bookManager.nextChapter()
        }
        .onReceive(NotificationCenter.default.publisher(for: .readerToggleDrawer)) { _ in
            withAnimation(.spring(response: 0.3)) {
                showDrawer.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .readerToggleSearch)) { _ in
            showSearch.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .readerToggleJumpPercent)) { _ in
            showJumpPercent.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .readerToggleSettings)) { _ in
            showSettings.toggle()
        }
    }

    // 空状态提示
    private var emptyPlaceholderView: some View {
        VStack(spacing: 18) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Reader for Mac")
                .font(.system(size: 20, weight: .bold))

            Text("轻量 · 原生 · 摸鱼看书神器")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            Button("打开电子书 (TXT / EPUB)...") {
                bookManager.promptOpenFile()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)

            Text("或直接拖拽小说文件至此窗口\n按 Cmd+Shift+H 可一键老板键隐藏")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(settings.currentTheme.backgroundColor.opacity(settings.backgroundOpacity))
    }

    // 悬浮工具栏
    private var floatingToolbar: some View {
        HStack(spacing: 8) {
            toolbarButton(icon: "folder", tooltip: "打开文件 (Cmd+O)") {
                bookManager.promptOpenFile()
            }

            toolbarButton(icon: "list.bullet", tooltip: "目录抽屉 (Cmd+L)") {
                withAnimation(.spring(response: 0.3)) {
                    showDrawer.toggle()
                }
            }

            toolbarButton(icon: "magnifyingglass", tooltip: "全文搜索 (Cmd+F)") {
                showSearch = true
            }

            toolbarButton(icon: "percent", tooltip: "进度跳转 (Cmd+G)") {
                showJumpPercent = true
            }

            toolbarButton(icon: "bookmark", tooltip: "书签列表 (添加快捷键 Cmd+D)") {
                showBookmarks = true
            }

            toolbarButton(icon: settings.autoScrollEnabled ? "pause.circle.fill" : "play.circle", tooltip: "自动翻页 (空格键)") {
                settings.autoScrollEnabled.toggle()
            }

            Divider().frame(height: 16)

            toolbarButton(icon: settings.isBorderless ? "square.dashed" : "macwindow", tooltip: "无边框模式 (F12 / Cmd+B)") {
                ReaderWindowController.shared.toggleBorderless()
            }

            toolbarButton(icon: settings.isAlwaysOnTop ? "pin.fill" : "pin", tooltip: "窗口置顶 (Cmd+T)") {
                ReaderWindowController.shared.toggleAlwaysOnTop()
            }

            toolbarButton(icon: "eye.slash", tooltip: "老板键瞬间隐藏 (Cmd+Shift+H)") {
                ReaderWindowController.shared.toggleBossKey()
            }

            toolbarButton(icon: "gearshape", tooltip: "偏好设置 (Cmd+,)") {
                showSettings = true
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
        )
    }

    private func toolbarButton(icon: String, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}

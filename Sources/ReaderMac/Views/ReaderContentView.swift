import SwiftUI
import AppKit

public struct ReaderContentView: View {
    @ObservedObject var book: Book
    @ObservedObject var settings: AppSettings = .shared

    // 自动滚动 Timer
    @State private var autoScrollTimer: Timer?
    @State private var scrollPosition: CGFloat = 0.0
    @State private var maxScrollHeight: CGFloat = 1000.0

    public var onScrollChanged: ((Double) -> Void)?

    public init(book: Book, onScrollChanged: ((Double) -> Void)? = nil) {
        self.book = book
        self.onScrollChanged = onScrollChanged
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 背景（根据主题与背景透明度设置）
                let theme = settings.currentTheme
                theme.backgroundColor
                    .opacity(settings.backgroundOpacity)
                    .ignoresSafeArea()

                // 核心文本滚动视口
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: !settings.isBorderless) {
                        VStack(alignment: .leading, spacing: CGFloat(settings.paragraphSpacing)) {
                            // 章节标题
                            if let chapter = book.currentChapter {
                                Text(chapter.title)
                                    .font(customFont(size: settings.fontSize + 6, bold: true))
                                    .foregroundColor(theme.textColor.opacity(settings.textOpacity))
                                    .padding(.bottom, CGFloat(settings.paragraphSpacing))
                                    .id("top_of_chapter")

                                // 章节段落
                                ForEach(splitParagraphs(chapter.content), id: \.self) { paragraph in
                                    Text(formatParagraph(paragraph))
                                        .font(customFont(size: settings.fontSize, bold: false))
                                        .lineSpacing(CGFloat(settings.lineSpacing))
                                        .foregroundColor(theme.textColor.opacity(settings.textOpacity))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            } else {
                                Text("未打开书籍，请按 Cmd+O 或拖拽 txt / epub 文件至窗口")
                                    .font(customFont(size: settings.fontSize, bold: false))
                                    .foregroundColor(theme.textColor.opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 100)
                            }
                        }
                        .padding(.horizontal, CGFloat(settings.horizontalPadding))
                        .padding(.top, CGFloat(settings.verticalPadding))
                        .padding(.bottom, CGFloat(settings.verticalPadding) + 40)
                    }
                    .background(GeometryReader { scrollGeo in
                        Color.clear.preference(key: ViewHeightKey.self, value: scrollGeo.size.height)
                    })
                }

                // 底部微型状态栏（在无边框摸鱼时低调半透明显示进度与章节）
                bottomStatusBar
            }
        }
        .onAppear {
            setupAutoScrollTimer()
        }
        .onDisappear {
            stopAutoScrollTimer()
        }
        .onChange(of: settings.autoScrollEnabled) { enabled in
            if enabled {
                setupAutoScrollTimer()
            } else {
                stopAutoScrollTimer()
            }
        }
        .onChange(of: settings.autoScrollSpeed) { _ in
            if settings.autoScrollEnabled {
                setupAutoScrollTimer()
            }
        }
    }

    // 格式化段落（首行缩进两个全角空格）
    private func formatParagraph(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        if settings.enableFirstLineIndent && !trimmed.hasPrefix("　　") && !trimmed.hasPrefix("    ") {
            return "　　" + trimmed
        }
        return trimmed
    }

    private func splitParagraphs(_ content: String) -> [String] {
        return content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func customFont(size: Double, bold: Bool) -> Font {
        if let _ = NSFont(name: settings.fontName, size: CGFloat(size)) {
            return Font.custom(settings.fontName, size: CGFloat(size)).weight(bold ? .bold : .regular)
        }
        return Font.system(size: CGFloat(size), weight: bold ? .bold : .regular)
    }

    // 底部状态条
    private var bottomStatusBar: some View {
        HStack {
            if let chapter = book.currentChapter {
                Text(chapter.title)
                    .lineLimit(1)
                Spacer()
                Text("第 \(book.currentChapterIndex + 1)/\(max(book.chapters.count, 1)) 章")
                Text(" · ")
                Text("\(chapter.content.count) 字")
                if settings.autoScrollEnabled {
                    Text(" · [自动翻页中 速度:\(Int(settings.autoScrollSpeed))]")
                        .foregroundColor(.green)
                }
            } else {
                Spacer()
            }
        }
        .font(.system(size: 11, weight: .regular, design: .monospaced))
        .foregroundColor(settings.currentTheme.textColor.opacity(settings.textOpacity * 0.55))
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(
            Color.black.opacity(settings.isBorderless ? 0.05 : 0.08)
        )
    }

    private func setupAutoScrollTimer() {
        stopAutoScrollTimer()
        guard settings.autoScrollEnabled else { return }

        // 根据速度换算定时器间隔 (0.03 秒 ~ 0.08 秒微滚)
        let interval = 0.05
        let step = CGFloat(settings.autoScrollSpeed * 0.4)

        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            // 发出小幅度滚动事件
            NotificationCenter.default.post(name: .readerScrollStep, object: step)
        }
    }

    private func stopAutoScrollTimer() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
}

public extension Notification.Name {
    static let readerScrollStep = Notification.Name("readerScrollStep")
    static let readerScrollToPercent = Notification.Name("readerScrollToPercent")
    static let readerPrevChapter = Notification.Name("readerPrevChapter")
    static let readerNextChapter = Notification.Name("readerNextChapter")
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

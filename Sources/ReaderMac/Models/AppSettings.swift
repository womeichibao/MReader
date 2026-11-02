import SwiftUI
import AppKit

public enum PageMode: String, Codable, CaseIterable {
    case scroll = "连续滚动"
    case page = "左右分页"
}

public class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    private let settingsKey = "com.reader.app_settings"

    // 窗口与摸鱼设置
    @Published public var windowOpacity: Double = 1.0 { didSet { save() } }
    @Published public var backgroundOpacity: Double = 1.0 { didSet { save() } }
    @Published public var textOpacity: Double = 1.0 { didSet { save() } }
    @Published public var isBorderless: Bool = false { didSet { save() } }
    @Published public var isAlwaysOnTop: Bool = false { didSet { save() } }
    @Published public var autoHideOnMouseExit: Bool = false { didSet { save() } }
    @Published public var mouseExitDelay: Double = 1.5 { didSet { save() } }
    @Published public var mouseExitDimOpacity: Double = 0.1 { didSet { save() } }

    // 排版设置
    @Published public var fontName: String = "PingFang SC" { didSet { save() } }
    @Published public var fontSize: Double = 18.0 { didSet { save() } }
    @Published public var lineSpacing: Double = 8.0 { didSet { save() } }
    @Published public var paragraphSpacing: Double = 14.0 { didSet { save() } }
    @Published public var horizontalPadding: Double = 24.0 { didSet { save() } }
    @Published public var verticalPadding: Double = 20.0 { didSet { save() } }
    @Published public var enableFirstLineIndent: Bool = true { didSet { save() } }
    @Published public var enableWordWrap: Bool = true { didSet { save() } }

    // 主题与色彩
    @Published public var selectedThemeId: String = ReadingTheme.parchment.id { didSet { save() } }
    @Published public var customTheme: ReadingTheme? = nil { didSet { save() } }

    // 翻页与滚轮
    @Published public var pageMode: PageMode = .scroll { didSet { save() } }
    @Published public var autoScrollEnabled: Bool = false { didSet { save() } }
    @Published public var autoScrollSpeed: Double = 2.0 { didSet { save() } } // 1.0 ~ 10.0
    @Published public var scrollStepDistance: Double = 120.0 { didSet { save() } } // 键盘方向键单次滚动距离

    // 正则表达式识别目录
    @Published public var chapterRegexPattern: String = #"^\s*(第[0-9一二三四五六七八九十百千万]+[章回节卷集部篇幕]|Chapter\s+\d+|[0-9]+\s+).*"# { didSet { save() } }

    public var currentTheme: ReadingTheme {
        if let custom = customTheme, custom.id == selectedThemeId {
            return custom
        }
        return ReadingTheme.allThemes.first { $0.id == selectedThemeId } ?? .parchment
    }

    private init() {
        load()
    }

    private struct SettingsStorage: Codable {
        var windowOpacity: Double
        var backgroundOpacity: Double
        var textOpacity: Double
        var isBorderless: Bool
        var isAlwaysOnTop: Bool
        var autoHideOnMouseExit: Bool
        var mouseExitDelay: Double
        var mouseExitDimOpacity: Double

        var fontName: String
        var fontSize: Double
        var lineSpacing: Double
        var paragraphSpacing: Double
        var horizontalPadding: Double
        var verticalPadding: Double
        var enableFirstLineIndent: Bool
        var enableWordWrap: Bool

        var selectedThemeId: String
        var pageMode: PageMode
        var autoScrollSpeed: Double
        var scrollStepDistance: Double
        var chapterRegexPattern: String
    }

    private func save() {
        let storage = SettingsStorage(
            windowOpacity: windowOpacity,
            backgroundOpacity: backgroundOpacity,
            textOpacity: textOpacity,
            isBorderless: isBorderless,
            isAlwaysOnTop: isAlwaysOnTop,
            autoHideOnMouseExit: autoHideOnMouseExit,
            mouseExitDelay: mouseExitDelay,
            mouseExitDimOpacity: mouseExitDimOpacity,
            fontName: fontName,
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            paragraphSpacing: paragraphSpacing,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding,
            enableFirstLineIndent: enableFirstLineIndent,
            enableWordWrap: enableWordWrap,
            selectedThemeId: selectedThemeId,
            pageMode: pageMode,
            autoScrollSpeed: autoScrollSpeed,
            scrollStepDistance: scrollStepDistance,
            chapterRegexPattern: chapterRegexPattern
        )
        if let data = try? JSONEncoder().encode(storage) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let storage = try? JSONDecoder().decode(SettingsStorage.self, from: data) else {
            return
        }
        self.windowOpacity = storage.windowOpacity
        self.backgroundOpacity = storage.backgroundOpacity
        self.textOpacity = storage.textOpacity
        self.isBorderless = storage.isBorderless
        self.isAlwaysOnTop = storage.isAlwaysOnTop
        self.autoHideOnMouseExit = storage.autoHideOnMouseExit
        self.mouseExitDelay = storage.mouseExitDelay
        self.mouseExitDimOpacity = storage.mouseExitDimOpacity

        self.fontName = storage.fontName
        self.fontSize = storage.fontSize
        self.lineSpacing = storage.lineSpacing
        self.paragraphSpacing = storage.paragraphSpacing
        self.horizontalPadding = storage.horizontalPadding
        self.verticalPadding = storage.verticalPadding
        self.enableFirstLineIndent = storage.enableFirstLineIndent
        self.enableWordWrap = storage.enableWordWrap

        self.selectedThemeId = storage.selectedThemeId
        self.pageMode = storage.pageMode
        self.autoScrollSpeed = storage.autoScrollSpeed
        self.scrollStepDistance = storage.scrollStepDistance
        self.chapterRegexPattern = storage.chapterRegexPattern
    }
}

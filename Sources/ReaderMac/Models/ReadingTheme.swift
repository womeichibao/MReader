import SwiftUI
import AppKit

public struct ReadingTheme: Identifiable, Codable, Equatable {
    public var id: String
    public var name: String
    /// 背景 RGBA
    public var bgRed: Double
    public var bgGreen: Double
    public var bgBlue: Double
    public var bgAlpha: Double
    /// 文字 RGBA
    public var textRed: Double
    public var textGreen: Double
    public var textBlue: Double
    public var textAlpha: Double

    public init(id: String, name: String, bg: (Double, Double, Double, Double), text: (Double, Double, Double, Double)) {
        self.id = id
        self.name = name
        self.bgRed = bg.0
        self.bgGreen = bg.1
        self.bgBlue = bg.2
        self.bgAlpha = bg.3
        self.textRed = text.0
        self.textGreen = text.1
        self.textBlue = text.2
        self.textAlpha = text.3
    }

    public var backgroundColor: Color {
        Color(.sRGB, red: bgRed, green: bgGreen, blue: bgBlue, opacity: bgAlpha)
    }

    public var textColor: Color {
        Color(.sRGB, red: textRed, green: textGreen, blue: textBlue, opacity: textAlpha)
    }

    public var nsBackgroundColor: NSColor {
        NSColor(srgbRed: bgRed, green: bgGreen, blue: bgBlue, alpha: bgAlpha)
    }

    public var nsTextColor: NSColor {
        NSColor(srgbRed: textRed, green: textGreen, blue: textBlue, alpha: textAlpha)
    }

    // 预设主题列表
    public static let parchment = ReadingTheme(
        id: "parchment",
        name: "羊皮纸",
        bg: (0.96, 0.93, 0.85, 1.0),
        text: (0.24, 0.18, 0.12, 1.0)
    )

    public static let eyeCare = ReadingTheme(
        id: "eyecare",
        name: "护眼绿",
        bg: (0.88, 0.93, 0.88, 1.0),
        text: (0.15, 0.28, 0.15, 1.0)
    )

    public static let classicWhite = ReadingTheme(
        id: "classic_white",
        name: "简约白",
        bg: (0.98, 0.98, 0.98, 1.0),
        text: (0.15, 0.15, 0.15, 1.0)
    )

    public static let darkNight = ReadingTheme(
        id: "dark_night",
        name: "暗黑夜间",
        bg: (0.12, 0.12, 0.14, 1.0),
        text: (0.75, 0.75, 0.78, 1.0)
    )

    public static let hackerGreen = ReadingTheme(
        id: "hacker_green",
        name: "终端代码风",
        bg: (0.08, 0.09, 0.10, 0.95),
        text: (0.30, 0.85, 0.40, 1.0)
    )

    public static let transparentStealth = ReadingTheme(
        id: "transparent_stealth",
        name: "隐蔽透明 (摸鱼神器)",
        bg: (0.0, 0.0, 0.0, 0.0),
        text: (0.70, 0.70, 0.75, 0.85)
    )

    public static let allThemes: [ReadingTheme] = [
        .parchment,
        .eyeCare,
        .classicWhite,
        .darkNight,
        .hackerGreen,
        .transparentStealth
    ]
}

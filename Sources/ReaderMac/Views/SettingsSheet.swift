import SwiftUI
import AppKit

public struct SettingsSheet: View {
    @ObservedObject var settings: AppSettings = .shared
    @Binding var isPresented: Bool

    @State private var selectedTab: Int = 0

    public var body: some View {
        VStack(spacing: 0) {
            // 顶部标题
            HStack {
                Text("偏好设置 (Reader for Mac)")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            // 切换标签
            Picker("", selection: $selectedTab) {
                Text("摸鱼隐蔽").tag(0)
                Text("排版字体").tag(1)
                Text("主题配色").tag(2)
                Text("快捷键与高级").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 12)

            Divider()

            // 内容区
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if selectedTab == 0 {
                        stealthSettingsView
                    } else if selectedTab == 1 {
                        typographySettingsView
                    } else if selectedTab == 2 {
                        themeSettingsView
                    } else {
                        hotkeyAndAdvancedSettingsView
                    }
                }
                .padding()
            }

            Divider()

            // 底部关闭
            HStack {
                Spacer()
                Button("完成") {
                    ReaderWindowController.shared.applySettings()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(12)
        }
        .frame(width: 480, height: 500)
        .background(.ultraThinMaterial)
    }

    // 1. 摸鱼与隐蔽设置
    private var stealthSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                Toggle("无边框极简模式 (快捷键 F12 / Cmd+B)", isOn: $settings.isBorderless)
                    .onChange(of: settings.isBorderless) { _ in
                        ReaderWindowController.shared.applySettings()
                    }

                Toggle("窗口始终置顶 (快捷键 Cmd+T)", isOn: $settings.isAlwaysOnTop)
                    .onChange(of: settings.isAlwaysOnTop) { _ in
                        ReaderWindowController.shared.applySettings()
                    }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("窗口整体透明度:")
                        Spacer()
                        Text("\(Int(settings.windowOpacity * 100))%")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.windowOpacity, in: 0.1...1.0, step: 0.05)
                        .onChange(of: settings.windowOpacity) { _ in
                            ReaderWindowController.shared.applySettings()
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("背景透明度 (支持背景全透明、文字不透明):")
                        Spacer()
                        Text("\(Int(settings.backgroundOpacity * 100))%")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.backgroundOpacity, in: 0.0...1.0, step: 0.05)
                        .onChange(of: settings.backgroundOpacity) { _ in
                            ReaderWindowController.shared.applySettings()
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("文字透明度:")
                        Spacer()
                        Text("\(Int(settings.textOpacity * 100))%")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.textOpacity, in: 0.2...1.0, step: 0.05)
                }

                Divider()

                Toggle("鼠标移出窗口后自动隐蔽", isOn: $settings.autoHideOnMouseExit)

                if settings.autoHideOnMouseExit {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("移出延迟:")
                            Spacer()
                            Text(String(format: "%.1f 秒", settings.mouseExitDelay))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.mouseExitDelay, in: 0.5...5.0, step: 0.5)

                        HStack {
                            Text("移出后淡化透明度:")
                            Spacer()
                            Text("\(Int(settings.mouseExitDimOpacity * 100))%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.mouseExitDimOpacity, in: 0.0...0.5, step: 0.05)
                    }
                    .padding(.leading, 20)
                }
            }
        }
    }

    // 2. 排版字体设置
    private var typographySettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("字体:")
                Picker("", selection: $settings.fontName) {
                    Text("苹方 (PingFang SC)").tag("PingFang SC")
                    Text("宋体 (Songti SC)").tag("Songti SC")
                    Text("楷体 (Kaiti SC)").tag("Kaiti SC")
                    Text("圆体 (Yuanti SC)").tag("Yuanti SC")
                    Text("等宽 (Monaco)").tag("Monaco")
                }
                .frame(width: 200)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("字号大小 (快捷键 Cmd+= / Cmd+-):")
                    Spacer()
                    Text("\(Int(settings.fontSize)) pt")
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.fontSize, in: 12...32, step: 1)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("行间距:")
                    Spacer()
                    Text("\(Int(settings.lineSpacing)) pt")
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.lineSpacing, in: 2...20, step: 1)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("段间距:")
                    Spacer()
                    Text("\(Int(settings.paragraphSpacing)) pt")
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.paragraphSpacing, in: 4...28, step: 1)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("左右内边距:")
                    Spacer()
                    Text("\(Int(settings.horizontalPadding)) pt")
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.horizontalPadding, in: 8...60, step: 2)
            }

            Toggle("首行缩进两个字符", isOn: $settings.enableFirstLineIndent)
        }
    }

    // 3. 主题配色
    private var themeSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("预设阅读主题:")
                .font(.system(size: 13, weight: .semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ReadingTheme.allThemes) { theme in
                    Button(action: {
                        settings.selectedThemeId = theme.id
                        ReaderWindowController.shared.applySettings()
                    }) {
                        HStack {
                            Circle()
                                .fill(theme.backgroundColor)
                                .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(theme.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            if settings.selectedThemeId == theme.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(settings.selectedThemeId == theme.id ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(settings.selectedThemeId == theme.id ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // 4. 快捷键与高级
    private var hotkeyAndAdvancedSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("自动翻页滚动速度:")
                    Spacer()
                    Text("\(Int(settings.autoScrollSpeed)) 档")
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.autoScrollSpeed, in: 1...10, step: 1)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("章节识别正则表达式:")
                    .font(.system(size: 12, weight: .semibold))
                TextField("", text: $settings.chapterRegexPattern)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                Text("用于打开 TXT 小说时自动抓取分章。")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Divider()

            Text("常用快捷键指南:")
                .font(.system(size: 13, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                shortcutRow(keys: "Cmd+Shift+H / Option+H", desc: "老板键：瞬间隐藏 / 唤醒窗口")
                shortcutRow(keys: "F12 / Cmd+B", desc: "切换无边框极简模式 (任意拖拽)")
                shortcutRow(keys: "Cmd+T", desc: "切换窗口始终置顶")
                shortcutRow(keys: "空格键", desc: "开始 / 暂停自动平滑翻页")
                shortcutRow(keys: "Cmd+左右箭头", desc: "快速跳转上一章 / 下一章")
                shortcutRow(keys: "上下箭头 / 滚轮", desc: "上下微调滚动")
                shortcutRow(keys: "Cmd+O", desc: "打开本地 TXT / EPUB 小说")
                shortcutRow(keys: "Cmd+L", desc: "打开章节目录抽屉")
                shortcutRow(keys: "Cmd+F", desc: "全文关键词搜索")
                shortcutRow(keys: "Cmd+G", desc: "按百分比快速跳转进度")
                shortcutRow(keys: "Cmd+D", desc: "添加书签")
                shortcutRow(keys: "Cmd+,", desc: "打开偏好设置")
            }
            .font(.system(size: 11))
        }
    }

    private func shortcutRow(keys: String, desc: String) -> some View {
        HStack {
            Text(keys)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(4)
                .frame(width: 170, alignment: .leading)
            Text(desc)
                .foregroundColor(.secondary)
        }
    }
}

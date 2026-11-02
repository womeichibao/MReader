# MReader (Reader for Mac)

<p align="center">
  <strong>基于 Swift 6 与 AppKit / SwiftUI 构建的原生轻量级 macOS 小说阅读器</strong><br>
  轻量极简 · 低资源占用 · 无边框拖拽 · 双通道透明度 · 摸鱼看书神器
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Language-Swift%206-orange.svg" alt="Language">
  <img src="https://img.shields.io/badge/Arch-Apple%20Silicon%20%7C%20Intel-green.svg" alt="Architecture">
  <img src="https://img.shields.io/badge/Executable%20Size-1.4MB-brightgreen.svg" alt="Size">
</p>

---

## 📖 项目简介

**MReader** 是参考 Windows 知名开源阅读器 [binbyu/Reader](https://github.com/binbyu/Reader) 开发的 macOS 原生移植与升级版本。

针对 macOS 平台进行了专属深度定制，采用 **Swift 6 + AppKit / SwiftUI + CoreText** 原生技术栈实现，完全不依赖任何第三方重量级框架（无 Electron、无臃肿依赖），可执行文件仅 **1.4MB**，内存占用仅 **15~25MB**，毫秒级冷启动。

具备双通道透明度控制（背景全透明/文字半透明）、无边框窗口全局拖拽、老板键一键隐藏、防乱码智能编码识别、TXT 自定义正则目录解析、EPUB 原生解析等核心特性，专为学习、办公与低调摸鱼看书打造。

---

## ✨ 核心特性

- **极致原生与轻量**：纯 Swift 原生代码打造，体积仅 1.4MB，系统资源占用几乎可以忽略。
- **摸鱼与隐蔽神技**：
  - **无边框极简模式 (`F12` 或 `Cmd + B`)**：移除标题栏与边框，在窗口任意区域均可直接拖拽移动。
  - **双通道透明度调节**：独立调节窗口背景透明度与文字透明度（支持**背景 100% 全透明**，仅文字低调悬浮在代码或桌面上）。
  - **老板键瞬间隐蔽 (`Cmd + Shift + H` / `Option + H`)**：毫秒级隐藏或唤醒窗口。
  - **鼠标移出自动虚化**：鼠标离开窗口区域后可自动降低至极低透明度，鼠标移回立刻恢复。
  - **窗口置顶 (`Cmd + T`)**：支持常驻屏幕顶层。
- **全格式与防乱码**：
  - **TXT 编码自动识别**：智能检测 UTF-8、GB18030、GBK、GB2312、Big5、UTF-16，彻底告别 Windows 文本乱码。
  - **智能正则目录提取**：自动根据章节标题正则（支持自定义）提取小说目录，百万字瞬间建立章节索引。
  - **EPUB 电子书解析**：原生解压与解析 EPUB 目录及章节正文。
- **细致的排版与配色**：
  - 支持字号调节 (`Cmd + =` / `Cmd + -`)、字体切换（苹方、宋体、楷体、等宽等）、行距、段距、内边距、首行缩进两个字符。
  - 预设 6 款精选主题：羊皮纸、护眼绿、简约白、暗黑夜间、终端代码绿字、完全隐蔽透明。
- **控制与导航**：
  - 支持键盘翻页、滚轮平滑滚动、自动翻页（速度可调，按空格键开始/暂停）。
  - 侧边目录抽屉、全文关键字搜索定位、百分比精准进度跳转、书签收藏。
  - 本地自动记忆阅读进度与历史，重新打开即刻续读。

---

## ⌨️ 常用快捷键

| 快捷键 | 功能说明 |
| :--- | :--- |
| **`Cmd + Shift + H` / `Option + H`** | **老板键：一键瞬间隐藏 / 显示窗口** |
| **`F12` / `Cmd + B`** | **切换无边框极简模式（全窗口任意区域可拖动）** |
| **`F11` / `Esc`** | **全屏模式切换 / 退出全屏** |
| **`Cmd + T`** | **窗口置顶 / 取消置顶** |
| **`空格键`** | 开始 / 暂停自动平滑翻页 |
| **`Cmd + 左箭头` / `Cmd + 右箭头`** | 快速跳转上一章 / 下一章 |
| **`上箭头` / `下箭头`** | 向上 / 向下微调平滑滚动 |
| **`Cmd + =` / `Cmd + -`** | 放大 / 缩小字号 |
| **`Cmd + O`** | 打开本地电子书文件（亦支持直接拖入窗口） |
| **`Cmd + L`** | 打开 / 关闭章节目录抽屉 |
| **`Cmd + F`** | 打开全文关键字搜索面板 |
| **`Cmd + G`** | 打开按百分比快速跳转进度窗口 |
| **`Cmd + D`** | 添加当前位置到书签 |
| **`Cmd + ,`** | 打开偏好设置面板 |

---

## 🚀 编译与运行

### 1. 快速启动（开发调试）
```bash
./scripts/run.sh
```
或者直接使用 Swift 运行：
```bash
swift run
```

### 2. 打包生成独立的 `Reader.app`
```bash
./scripts/build.sh
```
打包成功后，将在 `dist/Reader.app` 生成可执行应用包，可以直接拖入系统的 `/Applications` 文件夹中使用。

---

## 🛠️ 项目结构

```
.
├── Package.swift                    # Swift Package 项目定义
├── scripts/
│   ├── build.sh                     # Release 编译与生成 Reader.app Bundle 脚本
│   ├── run.sh                       # 快速编译启动脚本
│   └── Info.plist                   # macOS 应用 Bundle 配置元数据
└── Sources/
    └── ReaderMac/
        ├── App/
        │   ├── main.swift           # 应用启动入口
        │   └── AppDelegate.swift    # 应用生命周期、系统主菜单、快捷键分发
        ├── Models/
        │   ├── Book.swift           # 书籍通用数据结构
        │   ├── BookManager.swift    # 书籍加载、章节切换、进度与书签调度
        │   ├── Chapter.swift        # 章节模型
        │   ├── AppSettings.swift    # 摸鱼设置、排版偏好、透明度与持久化存储
        │   ├── ReadingProgress.swift# 书签与历史阅读进度持久化管理
        │   └── ReadingTheme.swift   # 预设主题色彩（羊皮纸、护眼绿、暗黑、透明等）
        ├── Parsers/
        │   ├── EncodingDetector.swift # 智能文本编码识别（防乱码：UTF-8, GBK, Big5）
        │   ├── TxtParser.swift       # TXT 章节正则分章与正文索引构建
        │   └── EpubParser.swift      # EPUB 归档解压与章节 HTML 纯文本化
        ├── Window/
        │   ├── ReaderWindowController.swift # 摸鱼窗口核心：无边框、置顶、透明度、移出隐藏
        │   ├── MenuBarManager.swift         # macOS 菜单栏状态图标
        │   └── HotKeyManager.swift          # 本地/系统快捷键管理
        └── Views/
            ├── MainReaderView.swift         # 主阅读界面与悬浮摸鱼工具条
            ├── ReaderContentView.swift      # 核心文本排版渲染与自动翻页
            ├── ChapterDrawer.swift          # 目录抽屉面板
            ├── BookmarkView.swift           # 书签管理弹窗
            ├── SearchPanel.swift            # 全文搜索与定位面板
            ├── JumpPercentSheet.swift       # 百分比跳转弹窗
            └── SettingsSheet.swift          # 偏好设置面板
```

---

## 📜 开源许可与致谢

- 参考自 Windows 开源小说阅读器：[binbyu/Reader](https://github.com/binbyu/Reader)
- 本项目遵循开源规范，仅供学习、交流与个人电子书阅读使用。

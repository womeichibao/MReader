import Foundation
import AppKit
import UniformTypeIdentifiers

public class BookManager: ObservableObject {
    public static let shared = BookManager()

    @Published public var currentBook: Book?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?

    private init() {}

    public func promptOpenFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        var types: [UTType] = [.plainText]
        if let txtType = UTType(filenameExtension: "txt") {
            types.append(txtType)
        }
        if let epubType = UTType(filenameExtension: "epub") {
            types.append(epubType)
        }
        panel.allowedContentTypes = types

        if panel.runModal() == .OK, let url = panel.url {
            openFile(url: url)
        }
    }

    public func openFile(url: URL) {
        isLoading = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let book: Book
                let ext = url.pathExtension.lowercased()

                if ext == "epub" {
                    book = try EpubParser.parse(fileURL: url)
                } else {
                    book = try TxtParser.parse(fileURL: url)
                }

                DispatchQueue.main.async {
                    self.currentBook = book
                    self.isLoading = false

                    // 恢复历史进度
                    if let history = ReadingHistoryManager.shared.getHistory(for: book.filePath) {
                        if history.lastChapterIndex < book.chapters.count {
                            book.currentChapterIndex = history.lastChapterIndex
                        }
                    }

                    // 更新窗口标题
                    ReaderWindowController.shared.window?.title = "\(book.title) - Reader"
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "打开书籍失败: \(error.localizedDescription)"
                    print("Error loading book: \(error)")
                }
            }
        }
    }

    public func switchChapter(to index: Int) {
        guard let book = currentBook else { return }
        guard index >= 0 && index < book.chapters.count else { return }
        book.currentChapterIndex = index

        ReadingHistoryManager.shared.updateProgress(
            for: book.filePath,
            chapterIndex: index,
            scrollProgress: 0.0
        )
    }

    public func previousChapter() {
        guard let book = currentBook, book.currentChapterIndex > 0 else { return }
        switchChapter(to: book.currentChapterIndex - 1)
    }

    public func nextChapter() {
        guard let book = currentBook, book.currentChapterIndex + 1 < book.chapters.count else { return }
        switchChapter(to: book.currentChapterIndex + 1)
    }

    public func calculateOverallPercent() -> Double {
        guard let book = currentBook, !book.chapters.isEmpty else { return 0.0 }
        let percent = (Double(book.currentChapterIndex) / Double(book.chapters.count)) * 100.0
        return min(max(percent, 0.0), 100.0)
    }

    public func jumpToPercent(_ percent: Double) {
        guard let book = currentBook, !book.chapters.isEmpty else { return }
        let targetIndex = Int((percent / 100.0) * Double(book.chapters.count - 1))
        switchChapter(to: targetIndex)
    }

    public func addCurrentBookmark() {
        guard let book = currentBook, let chapter = book.currentChapter else { return }
        let snippet = String(chapter.content.prefix(40)).replacingOccurrences(of: "\n", with: " ")

        let bookmark = Bookmark(
            chapterIndex: chapter.index,
            chapterTitle: chapter.title,
            scrollProgress: 0.0,
            snippet: snippet
        )

        ReadingHistoryManager.shared.addBookmark(for: book.filePath, bookmark: bookmark)
    }
}

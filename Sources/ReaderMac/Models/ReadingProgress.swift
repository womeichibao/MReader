import Foundation

public struct Bookmark: Identifiable, Codable, Hashable {
    public var id: UUID
    public var chapterIndex: Int
    public var chapterTitle: String
    public var scrollProgress: Double
    public var snippet: String
    public var createdAt: Date

    public init(id: UUID = UUID(), chapterIndex: Int, chapterTitle: String, scrollProgress: Double, snippet: String, createdAt: Date = Date()) {
        self.id = id
        self.chapterIndex = chapterIndex
        self.chapterTitle = chapterTitle
        self.scrollProgress = scrollProgress
        self.snippet = snippet
        self.createdAt = createdAt
    }
}

public struct BookHistory: Codable {
    public let filePath: String
    public var lastChapterIndex: Int
    public var scrollProgress: Double // 0.0 - 1.0
    public var lastReadDate: Date
    public var bookmarks: [Bookmark]

    public init(filePath: String, lastChapterIndex: Int = 0, scrollProgress: Double = 0.0, lastReadDate: Date = Date(), bookmarks: [Bookmark] = []) {
        self.filePath = filePath
        self.lastChapterIndex = lastChapterIndex
        self.scrollProgress = scrollProgress
        self.lastReadDate = lastReadDate
        self.bookmarks = bookmarks
    }
}

public class ReadingHistoryManager {
    public static let shared = ReadingHistoryManager()
    private let userDefaultsKey = "com.reader.reading_history"

    private var historyMap: [String: BookHistory] = [:]

    private init() {
        load()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            historyMap = try JSONDecoder().decode([String: BookHistory].self, from: data)
        } catch {
            print("Failed to decode history: \(error)")
        }
    }

    public func save() {
        do {
            let data = try JSONEncoder().encode(historyMap)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to encode history: \(error)")
        }
    }

    public func getHistory(for filePath: String) -> BookHistory? {
        return historyMap[filePath]
    }

    public func updateProgress(for filePath: String, chapterIndex: Int, scrollProgress: Double) {
        var item = historyMap[filePath] ?? BookHistory(filePath: filePath)
        item.lastChapterIndex = chapterIndex
        item.scrollProgress = scrollProgress
        item.lastReadDate = Date()
        historyMap[filePath] = item
        save()
    }

    public func addBookmark(for filePath: String, bookmark: Bookmark) {
        var item = historyMap[filePath] ?? BookHistory(filePath: filePath)
        item.bookmarks.insert(bookmark, at: 0)
        historyMap[filePath] = item
        save()
    }

    public func removeBookmark(for filePath: String, bookmarkId: UUID) {
        guard var item = historyMap[filePath] else { return }
        item.bookmarks.removeAll { $0.id == bookmarkId }
        historyMap[filePath] = item
        save()
    }
}

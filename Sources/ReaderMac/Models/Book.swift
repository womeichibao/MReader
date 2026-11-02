import Foundation

public enum BookFormat: String, Codable {
    case txt
    case epub
    case unknown
}

public class Book: Identifiable, ObservableObject {
    public let id: UUID
    public let title: String
    public let filePath: String
    public let format: BookFormat
    public let fileSize: Int64

    @Published public var chapters: [Chapter] = []
    @Published public var currentChapterIndex: Int = 0
    @Published public var totalCharCount: Int = 0

    public init(id: UUID = UUID(), title: String, filePath: String, format: BookFormat, fileSize: Int64, chapters: [Chapter] = []) {
        self.id = id
        self.title = title
        self.filePath = filePath
        self.format = format
        self.fileSize = fileSize
        self.chapters = chapters
        self.totalCharCount = chapters.reduce(0) { $0 + $1.content.count }
    }

    public var currentChapter: Chapter? {
        guard currentChapterIndex >= 0 && currentChapterIndex < chapters.count else { return nil }
        return chapters[currentChapterIndex]
    }
}

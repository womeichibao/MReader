import Foundation

/// 表示电子书的一个章节
public struct Chapter: Identifiable, Codable, Hashable {
    public let id: UUID
    public let index: Int
    public let title: String
    /// 章节起始字节或字符偏移（用于大文本按需分片定位）
    public let offset: Int
    public let length: Int
    /// 章节正文（对于大文件可延迟或按需加载，小/中等文件直接常驻）
    public var content: String

    public init(id: UUID = UUID(), index: Int, title: String, offset: Int = 0, length: Int = 0, content: String = "") {
        self.id = id
        self.index = index
        self.title = title
        self.offset = offset
        self.length = length
        self.content = content
    }
}

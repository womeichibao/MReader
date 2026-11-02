import Foundation

public class TxtParser {
    public static func parse(fileURL: URL, regexPattern: String = AppSettings.shared.chapterRegexPattern) throws -> Book {
        let (rawContent, encodingName) = try EncodingDetector.detectAndRead(from: fileURL)
        print("Loaded \(fileURL.lastPathComponent) with encoding: \(encodingName), length: \(rawContent.count)")

        // 统一换行符
        let normalizedContent = rawContent.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        var chapters: [Chapter] = []

        // 尝试编译章节正则
        let regex = try? NSRegularExpression(pattern: regexPattern, options: [.anchorsMatchLines])

        let nsString = normalizedContent as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        var matches: [NSTextCheckingResult] = []
        if let regex = regex {
            matches = regex.matches(in: normalizedContent, options: [], range: fullRange)
        }

        if !matches.isEmpty {
            // 检查第 1 个章节前面是否有前言/引言
            let firstMatch = matches[0]
            if firstMatch.range.location > 0 {
                let introRange = NSRange(location: 0, length: firstMatch.range.location)
                let introText = nsString.substring(with: introRange).trimmingCharacters(in: .whitespacesAndNewlines)
                if !introText.isEmpty {
                    chapters.append(Chapter(
                        index: 0,
                        title: "前言 / 序章",
                        offset: 0,
                        length: introRange.length,
                        content: introText
                    ))
                }
            }

            // 遍历所有章节
            for i in 0..<matches.count {
                let currentMatch = matches[i]
                let title = nsString.substring(with: currentMatch.range).trimmingCharacters(in: .whitespacesAndNewlines)

                let startOffset = currentMatch.range.location
                let endOffset: Int
                if i + 1 < matches.count {
                    endOffset = matches[i + 1].range.location
                } else {
                    endOffset = nsString.length
                }

                let contentRange = NSRange(location: startOffset, length: endOffset - startOffset)
                let chapterContent = nsString.substring(with: contentRange)

                chapters.append(Chapter(
                    index: chapters.count,
                    title: title,
                    offset: startOffset,
                    length: contentRange.length,
                    content: chapterContent
                ))
            }
        } else {
            // 如果未能通过正则匹配到章节，按固定字数智能切分，保证阅读性能
            let chunkSize = 10000
            let totalLength = nsString.length

            if totalLength <= chunkSize {
                chapters.append(Chapter(
                    index: 0,
                    title: fileURL.deletingPathExtension().lastPathComponent,
                    offset: 0,
                    length: totalLength,
                    content: normalizedContent
                ))
            } else {
                var currentIndex = 0
                var chunkCount = 1

                while currentIndex < totalLength {
                    var currentChunkEnd = min(currentIndex + chunkSize, totalLength)

                    // 尽量在段落换行处切分
                    if currentChunkEnd < totalLength {
                        let searchRange = NSRange(location: currentChunkEnd - 500, length: 500)
                        let newlineRange = nsString.range(of: "\n", options: .backwards, range: searchRange)
                        if newlineRange.location != NSNotFound {
                            currentChunkEnd = newlineRange.location + 1
                        }
                    }

                    let range = NSRange(location: currentIndex, length: currentChunkEnd - currentIndex)
                    let text = nsString.substring(with: range)

                    chapters.append(Chapter(
                        index: chapters.count,
                        title: "第 \(chunkCount) 部分",
                        offset: currentIndex,
                        length: range.length,
                        content: text
                    ))

                    currentIndex = currentChunkEnd
                    chunkCount += 1
                }
            }
        }

        let bookTitle = fileURL.deletingPathExtension().lastPathComponent
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? 0

        return Book(
            title: bookTitle,
            filePath: fileURL.path,
            format: .txt,
            fileSize: fileSize,
            chapters: chapters
        )
    }
}

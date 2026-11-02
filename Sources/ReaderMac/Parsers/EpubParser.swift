import Foundation

public class EpubParser {
    public static func parse(fileURL: URL) throws -> Book {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ReaderEpub_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // 调用系统 unzip 解压
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", fileURL.path, "-d", tempDir.path]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(domain: "EpubParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "解压 EPUB 文件失败"])
        }

        // 1. 读取 META-INF/container.xml 找到 opf 路径
        let containerURL = tempDir.appendingPathComponent("META-INF/container.xml")
        guard let containerData = try? Data(contentsOf: containerURL),
              let containerXML = try? XMLDocument(data: containerData, options: []) else {
            throw NSError(domain: "EpubParser", code: 2, userInfo: [NSLocalizedDescriptionKey: "无法解析 container.xml"])
        }

        let rootfileNodes = try containerXML.nodes(forXPath: "//*[local-name()='rootfile']")
        guard let firstRootfile = rootfileNodes.first as? XMLElement,
              let fullPath = firstRootfile.attribute(forName: "full-path")?.stringValue else {
            throw NSError(domain: "EpubParser", code: 3, userInfo: [NSLocalizedDescriptionKey: "未找到 content.opf 路径"])
        }

        let opfURL = tempDir.appendingPathComponent(fullPath)
        let opfDir = opfURL.deletingLastPathComponent()

        guard let opfData = try? Data(contentsOf: opfURL),
              let opfXML = try? XMLDocument(data: opfData, options: []) else {
            throw NSError(domain: "EpubParser", code: 4, userInfo: [NSLocalizedDescriptionKey: "无法解析 OPF 文件"])
        }

        // 提取书名
        var bookTitle = fileURL.deletingPathExtension().lastPathComponent
        if let titleNode = try? opfXML.nodes(forXPath: "//*[local-name()='metadata']/*[local-name()='title']").first,
           let titleText = titleNode.stringValue, !titleText.isEmpty {
            bookTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 提取 manifest (id -> href)
        var manifest: [String: String] = [:]
        let itemNodes = try opfXML.nodes(forXPath: "//*[local-name()='manifest']/*[local-name()='item']")
        for item in itemNodes {
            if let el = item as? XMLElement,
               let id = el.attribute(forName: "id")?.stringValue,
               let href = el.attribute(forName: "href")?.stringValue {
                manifest[id] = href
            }
        }

        // 提取 spine (阅读顺序列表)
        let spineNodes = try opfXML.nodes(forXPath: "//*[local-name()='spine']/*[local-name()='itemref']")
        var spineIds: [String] = []
        for spine in spineNodes {
            if let el = spine as? XMLElement,
               let idref = el.attribute(forName: "idref")?.stringValue {
                spineIds.append(idref)
            }
        }

        // 提取各个章节文本
        var chapters: [Chapter] = []
        for (index, idref) in spineIds.enumerated() {
            guard let href = manifest[idref] else { continue }
            let chapterURL = opfDir.appendingPathComponent(href)
            guard let data = try? Data(contentsOf: chapterURL) else { continue }

            let (htmlContent, _) = (try? EncodingDetector.detectAndRead(from: data)) ?? (String(decoding: data, as: UTF8.self), "UTF-8")

            // 从 HTML 中提取标题与纯文本
            let (title, plainText) = extractTextAndTitle(from: htmlContent, defaultTitle: "第 \(index + 1) 章")

            if !plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                chapters.append(Chapter(
                    index: chapters.count,
                    title: title,
                    offset: 0,
                    length: plainText.count,
                    content: plainText
                ))
            }
        }

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? 0

        return Book(
            title: bookTitle,
            filePath: fileURL.path,
            format: .epub,
            fileSize: fileSize,
            chapters: chapters
        )
    }

    /// 从 XHTML/HTML 中清洗标签并提取标题与排版段落
    private static func extractTextAndTitle(from html: String, defaultTitle: String) -> (title: String, content: String) {
        var chapterTitle = defaultTitle

        // 尝试提取 <title> 或 <h1> / <h2>
        let titleRegex = try? NSRegularExpression(pattern: #"<title[^>]*>(.*?)</title>|<h[1-2][^>]*>(.*?)</h[1-2]>"#, options: [.caseInsensitive])
        if let match = titleRegex?.firstMatch(in: html, options: [], range: NSRange(location: 0, length: (html as NSString).length)) {
            let nsHtml = html as NSString
            let group1 = match.range(at: 1)
            let group2 = match.range(at: 2)
            let range = group1.location != NSNotFound ? group1 : group2
            if range.location != NSNotFound {
                let candidate = stripTags(from: nsHtml.substring(with: range)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !candidate.isEmpty && candidate.count < 60 {
                    chapterTitle = candidate
                }
            }
        }

        // 替换段落标签和换行
        var text = html
        text = text.replacingOccurrences(of: "<br/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "</div>", with: "\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "</h1>|</h2>|</h3>", with: "\n\n", options: [.regularExpression, .caseInsensitive])

        // 清除所有其它 HTML 标签
        text = stripTags(from: text)

        // 替换常见 HTML 实体
        let entities = [
            "&nbsp;": " ",
            "&emsp;": "　",
            "&ensp;": " ",
            "&quot;": "\"",
            "&apos;": "'",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&hellip;": "…"
        ]
        for (k, v) in entities {
            text = text.replacingOccurrences(of: k, with: v)
        }

        // 压缩过多空行（最多连续保留两个换行）
        let emptyLineRegex = try? NSRegularExpression(pattern: #"\n{3,}"#, options: [])
        if let emptyLineRegex = emptyLineRegex {
            text = emptyLineRegex.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: (text as NSString).length), withTemplate: "\n\n")
        }

        return (chapterTitle, text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func stripTags(from string: String) -> String {
        return string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

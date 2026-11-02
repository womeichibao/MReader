import SwiftUI

public struct SearchResultItem: Identifiable {
    public let id = UUID()
    public let chapterIndex: Int
    public let chapterTitle: String
    public let matchSnippet: String
}

public struct SearchPanel: View {
    @ObservedObject var book: Book
    @Binding var isPresented: Bool
    @State private var query: String = ""
    @State private var isSearching: Bool = false
    @State private var searchResults: [SearchResultItem] = []

    public var onSelectResult: (Int) -> Void

    public var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("全文关键字搜索")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            // 搜索输入栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("输入要查找的词句，按回车搜索...", text: $query, onCommit: executeSearch)
                    .textFieldStyle(.plain)
                if !query.isEmpty {
                    Button("搜索", action: executeSearch)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }
            .padding(10)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            // 搜索结果列表
            if isSearching {
                VStack {
                    Spacer()
                    ProgressView("正在全文搜索中...")
                    Spacer()
                }
            } else if searchResults.isEmpty && !query.isEmpty {
                VStack {
                    Spacer()
                    Text("未找到相关匹配内容")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List(searchResults) { result in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.chapterTitle)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.accentColor)
                        Text(result.matchSnippet)
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectResult(result.chapterIndex)
                        isPresented = false
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 420, height: 460)
        .background(.ultraThinMaterial)
    }

    private func executeSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 在主线程制作章节数据的局部不可变快照，避免后台并发遍历时主线程发生数据修改引发崩溃
        let chaptersSnapshot = book.chapters

        isSearching = true
        DispatchQueue.global(qos: .userInitiated).async {
            var results: [SearchResultItem] = []

            for chapter in chaptersSnapshot {
                let text = chapter.content
                if let range = text.range(of: trimmed, options: .caseInsensitive) {
                    let start = text.index(range.lowerBound, offsetBy: -30, limitedBy: text.startIndex) ?? text.startIndex
                    let end = text.index(range.upperBound, offsetBy: 50, limitedBy: text.endIndex) ?? text.endIndex
                    let snippet = "…" + text[start..<end].replacingOccurrences(of: "\n", with: " ") + "…"

                    results.append(SearchResultItem(
                        chapterIndex: chapter.index,
                        chapterTitle: chapter.title,
                        matchSnippet: snippet
                    ))

                    if results.count >= 200 { break }
                }
            }

            DispatchQueue.main.async {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }
}

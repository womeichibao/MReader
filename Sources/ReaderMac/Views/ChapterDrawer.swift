import SwiftUI

public struct ChapterDrawer: View {
    @ObservedObject var book: Book
    @Binding var isPresented: Bool
    @State private var filterText: String = ""

    public var onSelectChapter: (Int) -> Void

    public var filteredChapters: [Chapter] {
        if filterText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return book.chapters
        }
        return book.chapters.filter { $0.title.localizedCaseInsensitiveContains(filterText) }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 头部标题与关闭
            HStack {
                Text("目录 (\(book.chapters.count) 章)")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            // 搜索过滤框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索章节标题...", text: $filterText)
                    .textFieldStyle(.plain)
                if !filterText.isEmpty {
                    Button(action: { filterText = "" }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            // 章节列表
            ScrollViewReader { proxy in
                List(filteredChapters) { chapter in
                    HStack {
                        Text(chapter.title)
                            .font(.system(size: 13))
                            .lineLimit(1)
                            .foregroundColor(chapter.index == book.currentChapterIndex ? .accentColor : .primary)
                        Spacer()
                        if chapter.index == book.currentChapterIndex {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectChapter(chapter.index)
                        isPresented = false
                    }
                    .id(chapter.index)
                }
                .listStyle(.plain)
                .onAppear {
                    proxy.scrollTo(book.currentChapterIndex, anchor: .center)
                }
            }
        }
        .frame(width: 320)
        .background(.ultraThinMaterial)
    }
}

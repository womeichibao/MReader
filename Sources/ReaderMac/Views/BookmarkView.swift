import SwiftUI

public struct BookmarkView: View {
    @ObservedObject var book: Book
    @Binding var isPresented: Bool
    @State private var bookmarks: [Bookmark] = []

    public var onSelectBookmark: (Bookmark) -> Void

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("书签列表")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if bookmarks.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("当前书籍尚无书签\n按 Cmd+D 可在当前位置快速添加书签")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List(bookmarks) { bookmark in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bookmark.chapterTitle)
                                .font(.system(size: 13, weight: .semibold))
                            Text(bookmark.snippet)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Text(formattedDate(bookmark.createdAt))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        Spacer()
                        Button(action: {
                            removeBookmark(bookmark)
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectBookmark(bookmark)
                        isPresented = false
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 360, height: 400)
        .background(.ultraThinMaterial)
        .onAppear {
            loadBookmarks()
        }
    }

    private func loadBookmarks() {
        if let history = ReadingHistoryManager.shared.getHistory(for: book.filePath) {
            self.bookmarks = history.bookmarks
        }
    }

    private func removeBookmark(_ bookmark: Bookmark) {
        ReadingHistoryManager.shared.removeBookmark(for: book.filePath, bookmarkId: bookmark.id)
        loadBookmarks()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

import SwiftUI

public struct JumpPercentSheet: View {
    @Binding var isPresented: Bool
    @State private var percent: Double = 0.0
    var currentPercent: Double
    var onJump: (Double) -> Void

    public init(isPresented: Binding<Bool>, currentPercent: Double, onJump: @escaping (Double) -> Void) {
        self._isPresented = isPresented
        self.currentPercent = currentPercent
        self._percent = State(initialValue: currentPercent)
        self.onJump = onJump
    }

    public var body: some View {
        VStack(spacing: 20) {
            Text("按百分比快速跳转进度")
                .font(.system(size: 15, weight: .bold))

            HStack {
                Text("\(Int(percent))%")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .frame(width: 80)

                Slider(value: $percent, in: 0...100, step: 1)
            }
            .padding(.horizontal)

            HStack(spacing: 16) {
                Button("取消") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("跳转") {
                    onJump(percent)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 320)
        .background(.ultraThinMaterial)
    }
}

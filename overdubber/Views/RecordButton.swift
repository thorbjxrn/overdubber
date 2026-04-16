import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red.opacity(0.2) : Color.clear)
                    .frame(width: 96, height: 96)

                Circle()
                    .fill(Color.red)
                    .frame(width: 72, height: 72)
                    .scaleEffect(isPulsing ? 0.85 : 1.0)

                if isRecording {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 28, height: 28)
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isRecording)
        .onChange(of: isRecording) { _, recording in
            if recording {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPulsing = false
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        RecordButton(isRecording: false, action: {})
        RecordButton(isRecording: true, action: {})
    }
    .padding()
    .background(Color.black)
}

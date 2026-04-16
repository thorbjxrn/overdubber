import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void
    var recordColor: Color = .red

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(recordColor.opacity(isRecording ? 0.6 : 0.3), lineWidth: 1.5)
                    .frame(width: 96, height: 96)

                Circle()
                    .fill(recordColor)
                    .frame(width: 68, height: 68)
                    .scaleEffect(isPulsing ? 0.88 : 1.0)

                if isRecording {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 26, height: 26)
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

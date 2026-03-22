import SwiftUI

struct MindView: View {
    @State private var textVisible = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Text("Dharma Paramo Dharma")
                    .font(.custom("Georgia-Italic", size: 22))
                    .tracking(2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 72)
                    .scaleEffect(textVisible ? 1 : 0.3)
                    .opacity(textVisible ? 1 : 0)
                    .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 1.8).delay(0.2), value: textVisible)

                Spacer()
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 16_000_000)
            textVisible = true
        }
    }
}

#Preview {
    MindView()
}

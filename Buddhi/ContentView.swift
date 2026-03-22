import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image("BuddhaImage")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            Text("Buddhi")
                .font(.largeTitle)
                .bold()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

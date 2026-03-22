import SwiftUI

// MARK: - Dust Particle System

class DustParticles: ObservableObject {
    struct Particle {
        var x: CGFloat
        var y: CGFloat
        var radius: CGFloat
        var speed: CGFloat
        var drift: CGFloat
        var opacity: Double
        var maxOpacity: Double
        var delayFrames: Int
        var frameCount: Int = 0
    }

    var particles: [Particle] = []

    func initialize(size: CGSize) {
        particles = (0..<60).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: size.height + CGFloat.random(in: 0...300),
                radius: CGFloat.random(in: 0.2...1.8),
                speed: CGFloat.random(in: 0.1...0.65),
                drift: CGFloat.random(in: -0.125...0.125),
                opacity: 0,
                maxOpacity: Double.random(in: 0.08...0.53),
                delayFrames: Int.random(in: 0...100)
            )
        }
    }

    func update(size: CGSize) {
        for i in particles.indices {
            particles[i].frameCount += 1
            guard particles[i].frameCount >= particles[i].delayFrames else { continue }
            particles[i].y -= particles[i].speed
            particles[i].x += particles[i].drift
            particles[i].opacity = min(particles[i].opacity + 0.006, particles[i].maxOpacity)
            if particles[i].y < -10 {
                particles[i].y = size.height + 10
                particles[i].x = CGFloat.random(in: 0...size.width)
                particles[i].opacity = 0
            }
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var buddhaVisible = false
    @State private var buddhaScale: CGFloat = 1.0
    @State private var overlayOpacity: Double = 0
    @State private var showMind = false
    @StateObject private var dust = DustParticles()

    var body: some View {
        if showMind {
            MindView()
        } else {
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()

                    Image("BuddhaImage")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(buddhaScale, anchor: UnitPoint(x: 0.5, y: 0.0))
                        .offset(y: buddhaVisible ? 0 : geo.size.height)
                        .opacity(buddhaVisible ? 1 : 0)
                        .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 1.8).delay(0.05), value: buddhaVisible)
                        .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 1.8).delay(0.05), value: buddhaScale)
                        .onTapGesture { enterMind() }

                    // Dust particles
                    TimelineView(.animation) { timeline in
                        Canvas { ctx, size in
                            dust.update(size: size)
                            for p in dust.particles {
                                let fadeFactor = min((p.y / size.height) * 3, 1)
                                let alpha = p.opacity * fadeFactor
                                guard alpha > 0 else { continue }
                                ctx.fill(
                                    Path(ellipseIn: CGRect(
                                        x: p.x - p.radius,
                                        y: p.y - p.radius,
                                        width: p.radius * 2,
                                        height: p.radius * 2
                                    )),
                                    with: .color(Color(
                                        red: 220/255,
                                        green: 195/255,
                                        blue: 140/255,
                                        opacity: alpha
                                    ))
                                )
                            }
                        }
                        .id(timeline.date)
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                    // Black veil that closes in when entering the mind
                    Color.black
                        .opacity(overlayOpacity)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
                .task {
                    dust.initialize(size: geo.size)
                    try? await Task.sleep(nanoseconds: 16_000_000)
                    buddhaVisible = true
                    buddhaScale = 1.4
                }
            }
        }
    }

    private func enterMind() {
        // Zoom into the face and fade to black, then switch to MindView
        withAnimation(.easeIn(duration: 0.5)) {
            buddhaScale = 12.0
            overlayOpacity = 1.0
        }
        Task {
            try? await Task.sleep(nanoseconds: 550_000_000)
            showMind = true
        }
    }
}

#Preview {
    SplashView()
}

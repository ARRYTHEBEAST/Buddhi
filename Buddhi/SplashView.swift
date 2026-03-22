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

// MARK: - Menu Card

struct MenuCard: View {
    let label: String
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Text(label.uppercased())
                .font(.custom("Georgia", size: 11))
                .tracking(2)
                .foregroundColor(Color(red: 220/255, green: 195/255, blue: 140/255).opacity(0.5))
            Text(title)
                .font(.custom("Georgia-Italic", size: 22))
                .tracking(1)
                .foregroundColor(Color(red: 235/255, green: 215/255, blue: 170/255).opacity(0.92))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.45))
        .overlay(
            Rectangle()
                .stroke(
                    Color(red: 220/255, green: 195/255, blue: 140/255).opacity(0.2),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var buddhaVisible = false
    @StateObject private var dust = DustParticles()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                // Buddha — 1.5x screen width for zoom, scaledToFit so height scales naturally.
                // Center placed at y=0.75h so face sits in upper portion of screen.
                // Start at y=1.9h so head just peeks from the bottom.
                Image("BuddhaImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 3.0)
                    .position(
                        x: geo.size.width / 2,
                        y: buddhaVisible ? geo.size.height * 0.65 : geo.size.height * 1.9
                    )
                    .opacity(buddhaVisible ? 1 : 0)
                    .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 1.8).delay(0.05), value: buddhaVisible)

                // Dust particles — updated inside Canvas per frame via TimelineView
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
                    // Reference timeline.date so Canvas redraws every frame
                    .id(timeline.date)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

            }
            .task {
                dust.initialize(size: geo.size)
                // Wait one frame so SwiftUI captures the initial "from" state
                try? await Task.sleep(nanoseconds: 16_000_000)
                buddhaVisible = true
            }
        }
    }
}

#Preview {
    SplashView()
}

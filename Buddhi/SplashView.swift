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

// MARK: - Scanline

struct ScanlineView: View {
    let screenHeight: CGFloat
    @State private var height: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 220/255, green: 200/255, blue: 160/255).opacity(0.8),
                            Color.clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 1, height: height)
        }
        .frame(maxWidth: .infinity)
        .opacity(opacity)
        .task {
            try? await Task.sleep(nanoseconds: 16_000_000)
            withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 2.0).delay(0.1)) {
                height = screenHeight * 0.95
            }
            try? await Task.sleep(nanoseconds: 2_100_000_000)
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0
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
    @State private var glowVisible = false
    @State private var menuVisible = false
    @StateObject private var dust = DustParticles()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 180/255, green: 160/255, blue: 120/255).opacity(0.16),
                                Color(red: 100/255, green: 80/255, blue: 50/255).opacity(0.07),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 350
                        )
                    )
                    .frame(width: 700, height: 700)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.625)
                    .scaleEffect(glowVisible ? 1 : 0.3)
                    .opacity(glowVisible ? 1 : 0)
                    .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 3.5).delay(0.5), value: glowVisible)

                // Scanline
                ScanlineView(screenHeight: geo.size.height)

                // Buddha — use .position() so the image isn't clipped by ZStack layout.
                // Image is 2x screen height. We place its CENTER at y=screenHeight so
                // the top of the image lands exactly at the top of the screen.
                // Start: center at y=1.9h so only the head peeks from the bottom.
                Image("BuddhaImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width)
                    .position(
                        x: geo.size.width / 2,
                        y: buddhaVisible ? geo.size.height : geo.size.height * 1.9
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

                // Menu cards
                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        MenuCard(label: "Drink", title: "Madirā")
                        MenuCard(label: "Reflect", title: "Chintan")
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, geo.size.height * 0.07)
                }
                .opacity(menuVisible ? 1 : 0)
                .offset(y: menuVisible ? 0 : 12)
                .animation(.easeOut(duration: 2).delay(0.8), value: menuVisible)
            }
            .task {
                dust.initialize(size: geo.size)
                // Wait one frame so SwiftUI captures the initial "from" state
                try? await Task.sleep(nanoseconds: 16_000_000)
                buddhaVisible = true
                glowVisible = true
                menuVisible = true
            }
        }
    }
}

#Preview {
    SplashView()
}

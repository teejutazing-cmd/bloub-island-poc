import SwiftUI
import SpriteKit
import RealityKit
import UIKit

// Foreground-only animation renderer. Every lab mode selects a visible technique;
// nothing here purports to animate on system-managed Home/Island surfaces.
struct BloubMotionStage: View {
    let experiment: BloubExperiment
    let timestamp: TimeInterval
    let strength: Double
    let particles: Int
    let stress: Bool
    let burst: Int
    let touchOffset: CGSize
    let holding: Bool
    let audioLevel: CGFloat
    let tilt: CGFloat

    private var t: Double { timestamp.truncatingRemainder(dividingBy: 1000) }
    private var sine: Double { sin(t * 4) }
    private var cosine: Double { cos(t * 3) }
    private var fast: Double { sin(t * 13) }

    private var morphIndex: Int {
        if experiment == .gestureMorph {
            return max(0, min(23, Int(abs(touchOffset.width) / 7)))
        }
        return Int((t * 12).truncatingRemainder(dividingBy: 24))
    }

    private var scaleX: CGFloat {
        switch experiment {
        case .squash: return CGFloat(1.0 + sine * strength * 0.35)
        case .blink: return 1.0
        case .breathing, .neon: return CGFloat(1 + sine * strength * 0.13)
        case .elastic: return CGFloat(1 + sin(t * 11) * exp(-t.truncatingRemainder(dividingBy: 2)) * strength * 0.32)
        case .hold: return holding ? 1.45 : 1
        case .microphone: return 1 + audioLevel * CGFloat(strength)
        case .touch, .tapBurst: return CGFloat(1 + sin(Double(burst) * 1.5 + t * 8) * 0.15)
        default: return 1
        }
    }
    private var scaleY: CGFloat {
        switch experiment {
        case .squash: return CGFloat(1.0 - sine * strength * 0.32)
        case .blink: return CGFloat(max(0.08, 1 - pow(max(0, sin(t * 2.6)), 24) * 0.94))
        case .breathing, .neon: return scaleX
        case .bounce: return CGFloat(1 - abs(cosine) * 0.09)
        case .microphone: return scaleX
        case .hold: return holding ? 0.68 : 1
        default: return 1
        }
    }
    private var xOffset: CGFloat {
        switch experiment {
        case .shake, .glitch: return CGFloat(fast * strength * 17)
        case .throwDrag, .touch, .parallax, .gestureMorph: return touchOffset.width
        case .gyroscope: return tilt * 40
        case .spring: return CGFloat(sin(t * 8) * exp(-t.truncatingRemainder(dividingBy: 3)) * 95)
        default: return 0
        }
    }
    private var yOffset: CGFloat {
        switch experiment {
        case .bounce: return CGFloat(abs(sin(t * 4.6)) * -72 * strength)
        case .float, .layers, .reality: return CGFloat(sine * 22 * strength)
        case .throwDrag, .touch, .parallax, .gestureMorph: return touchOffset.height
        case .gravity: return CGFloat(abs(sin(t * 3)) * 62)
        default: return 0
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color(red: 0.09, green: 0.025, blue: 0.10),
                                        Color(red: 0.02, green: 0.04, blue: 0.11), .black],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                grid(size: geo.size)
                if experiment == .waves || experiment == .distortion || stress {
                    waveLines(size: geo.size)
                        .opacity(0.65)
                }
                if [.glow, .neon, .goo, .blur, .layers, .microphone, .sound].contains(experiment) || stress {
                    Circle()
                        .fill(Color.red.opacity(stress ? 0.8 : 0.6))
                        .frame(width: 130 + CGFloat(abs(sine) * 80), height: 130 + CGFloat(abs(sine) * 80))
                        .blur(radius: experiment == .goo ? 42 : 35)
                        .blendMode(.screen)
                }
                if experiment == .ripple || experiment == .shockwave || experiment == .neon || stress {
                    ripples
                }
                if experiment == .trail || experiment == .layers || stress {
                    ForEach(0..<8, id: \.self) { i in
                        BloubStill(mood: .working, size: CGFloat(55 + i * 7), frame: i % 5)
                            .opacity(Double(8 - i) * 0.045)
                            .offset(x: CGFloat(cos(t * 2 - Double(i) * 0.26) * (45 + Double(i) * 12)),
                                    y: CGFloat(sin(t * 2 - Double(i) * 0.26) * (20 + Double(i) * 7)))
                            .blendMode(.screen)
                    }
                }
                if experiment == .split || experiment == .goo {
                    ForEach(0..<3, id: \.self) { i in
                        BloubStill(mood: .working, size: 72, frame: i)
                            .offset(x: CGFloat(cos(Double(i) * 2.094 + t * 2) * abs(sine) * 85),
                                    y: CGFloat(sin(Double(i) * 2.094 + t * 2) * abs(sine) * 60))
                            .opacity(0.72)
                            .blur(radius: experiment == .goo ? 4 : 0)
                    }
                }
                coreAvatar
                    .scaleEffect(x: scaleX, y: scaleY)
                    .rotationEffect(.degrees(experiment == .spin ? t * 150 : experiment == .shake ? sine * 8 : 0))
                    .rotation3DEffect(.degrees(experiment == .rotate3D ? t * 85 :
                        experiment == .parallax ? Double(touchOffset.width) * 0.4 :
                        experiment == .gyroscope ? Double(tilt) * 35 : 0),
                        axis: (x: 0.3, y: 1, z: 0.1), perspective: 0.6)
                    .offset(x: xOffset, y: yOffset)
                    .blur(radius: experiment == .blur ? CGFloat(abs(sine) * 12) : 0)
                    .distortionEffect(
                        ShaderLibrary.bloubWarp(.float(Float(t)), .float(Float(strength))),
                        maxSampleOffset: CGSize(width: 32, height: 32),
                        isEnabled: experiment == .distortion || experiment == .waves || stress
                    )
                    .colorEffect(
                        ShaderLibrary.bloubColorShift(.float(Float(t)), .float(Float(strength))),
                        isEnabled: experiment == .glitch || experiment == .waves || stress
                    )
                if experiment == .particles || experiment == .explosion ||
                    experiment == .tapBurst || experiment == .shockwave || stress {
                    particlesCanvas(size: geo.size, count: stress ? max(200, particles) : particles)
                        .allowsHitTesting(false)
                }
                if experiment == .glitch {
                    HStack(spacing: 2) {
                        Rectangle().fill(.cyan.opacity(0.2))
                        Rectangle().fill(.red.opacity(0.2))
                        Rectangle().fill(.clear)
                    }
                    .frame(height: CGFloat(abs(fast) * 24 + 1))
                    .offset(y: CGFloat(sin(t * 17) * 112))
                    .blendMode(.screen)
                }
                if experiment == .layers {
                    ForEach(0..<5, id: \.self) { i in
                        Circle().stroke(Color.cyan.opacity(0.2), lineWidth: 2)
                            .frame(width: CGFloat(115 + i * 30), height: CGFloat(115 + i * 30))
                            .rotation3DEffect(.degrees(t * Double(25 + i * 9)), axis: (x: 1, y: 0.8, z: 0))
                    }
                }
                if experiment == .haptics || experiment == .sound {
                    Text(experiment == .haptics ? "TAP HAPTIC BELOW" : "TAP SOUND BELOW")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .offset(y: 114)
                }
                if experiment == .microphone {
                    Text("MIC LEVEL \(Int(audioLevel * 100))%")
                        .font(.caption2.monospacedDigit())
                        .offset(y: 115)
                }
                if stress {
                    VStack {
                        HStack {
                            Text("RENDER · 60Hz TARGET").font(.system(size: 9, design: .monospaced))
                            Spacer()
                            Text("\(min(600, particles)) PARTICLES").font(.system(size: 9, design: .monospaced))
                        }
                        Spacer()
                    }.padding(8).foregroundStyle(.orange)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    @ViewBuilder private var coreAvatar: some View {
        if experiment == .morph || experiment == .gestureMorph {
            BloubMorphFrame(frame: morphIndex, size: 115)
        } else {
            BloubStill(mood: .working, size: experiment == .explosion ? 65 : 118,
                       frame: Int(abs(sin(t * 1.4)) * 5) % 5)
        }
    }

    private func grid(size: CGSize) -> some View {
        Canvas(rendersAsynchronously: true) { context, bounds in
            var path = Path()
            let step = CGFloat(26)
            stride(from: CGFloat(0), through: bounds.width, by: step).forEach { x in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: bounds.height))
            }
            stride(from: CGFloat(0), through: bounds.height, by: step).forEach { y in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: bounds.width, y: y))
            }
            context.stroke(path, with: .color(Color.cyan.opacity(0.075)), lineWidth: 0.5)
        }
    }

    private var ripples: some View {
        ForEach(0..<6, id: \.self) { index in
            let phase = (t * 0.68 + Double(index) * 0.18).truncatingRemainder(dividingBy: 1)
            Circle()
                .stroke(index.isMultiple(of: 2) ? .cyan : .red, lineWidth: 1.5)
                .frame(width: CGFloat(20 + phase * 270), height: CGFloat(20 + phase * 270))
                .opacity(1 - phase)
        }
    }

    private func waveLines(size: CGSize) -> some View {
        Canvas(rendersAsynchronously: true) { context, bounds in
            for band in 0..<11 {
                var path = Path()
                let base = Double(band) * Double(bounds.height) / 11
                for x in stride(from: 0.0, through: Double(bounds.width), by: 6.0) {
                    let y = base + sin(x * 0.037 + t * 4 + Double(band) * 0.7) * (10 + strength * 17)
                    if x == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                context.stroke(path, with: .color(Color(red: 0.4, green: 0.9, blue: 1.0).opacity(0.5)), lineWidth: 1)
            }
        }
    }

    private func particlesCanvas(size: CGSize, count: Int) -> some View {
        Canvas(rendersAsynchronously: true) { context, bounds in
            let n = min(600, max(10, count))
            let explode = experiment == .explosion || experiment == .tapBurst || experiment == .shockwave
            for i in 0..<n {
                let seed = Double(i) * 1.61803398875
                let radius = Double((i * 73) % 120) * (explode ? (0.2 + abs(sin(t * 2))) : 1)
                let phase = seed * 6.28 + t * (0.7 + Double(i % 7) * 0.09)
                let cx = Double(bounds.midX) + cos(phase) * radius +
                    (explode ? Double(burst % 7) * 3 : 0)
                let cy = Double(bounds.midY) + sin(phase) * radius * 0.8
                let diameter = CGFloat(1.4 + Double(i % 5) * 0.8)
                let rect = CGRect(x: cx, y: cy, width: Double(diameter), height: Double(diameter))
                context.fill(Path(ellipseIn: rect),
                             with: .color(i.isMultiple(of: 3) ? Color.cyan : Color.red.opacity(0.82)))
            }
        }
    }
}

// Real SpriteKit collision/gravity engine; scene stays alive while selected.
private final class BloubPhysicsScene: SKScene {
    private var lastMode: Bool?
    override func didMove(to view: SKView) { backgroundColor = .black }
    func configure(collision: Bool) {
        guard lastMode != collision || children.isEmpty else { return }
        lastMode = collision
        removeAllChildren()
        backgroundColor = SKColor(red: 0.025, green: 0.035, blue: 0.07, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: -7)
        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 5, y: 5, width: 310, height: 248))
        for index in 0..<(collision ? 10 : 5) {
            let node = SKSpriteNode(imageNamed: "bloub-still-working")
            node.size = CGSize(width: index.isMultiple(of: 2) ? 43 : 32, height: index.isMultiple(of: 2) ? 43 : 32)
            node.position = CGPoint(x: 40 + (index * 38) % 238, y: 215 + (index % 3) * 11)
            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width * 0.37)
            node.physicsBody?.restitution = collision ? 0.85 : 0.46
            node.physicsBody?.friction = 0.19
            node.physicsBody?.linearDamping = 0.10
            node.physicsBody?.mass = 0.18
            addChild(node)
        }
    }
}

struct PhysicsBallStage: View {
    let collision: Bool
    let reset: Int
    @State private var scene = BloubPhysicsScene(size: CGSize(width: 320, height: 260))

    var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .onAppear { scene.scaleMode = .resizeFill; scene.configure(collision: collision) }
            .onChange(of: collision) { _, value in scene.configure(collision: value) }
            .onChange(of: reset) { _, _ in scene.removeAllChildren(); scene.configure(collision: collision) }
            .accessibilityLabel("Real SpriteKit physics simulation with bouncing Bloub sprites")
    }
}

// Actual RealityKit non-AR 3D geometry. No camera session or AR permission.
struct RealityBallStage: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(.black)
        let anchor = AnchorEntity(world: .zero)
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.18),
                                 materials: [SimpleMaterial(color: .red, isMetallic: true)])
        sphere.position = SIMD3<Float>(0, 0, -0.75)
        anchor.addChild(sphere)
        let ring = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.44, 0.015, 0.035)),
                               materials: [SimpleMaterial(color: .cyan, isMetallic: true)])
        ring.position = SIMD3<Float>(0, -0.3, -0.8)
        anchor.addChild(ring)
        view.scene.addAnchor(anchor)
        return view
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
}

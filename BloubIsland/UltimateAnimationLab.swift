import SwiftUI
import UIKit
import SpriteKit
import RealityKit
import CoreMotion
import AVFoundation
import CoreHaptics

// Each entry is a real, selectable lab experiment. System-owned surfaces are
// tested separately; these continuous animations run only inside the foreground app.
enum BloubExperiment: String, CaseIterable, Identifiable {
    case morph = "Original 24-frame morph"
    case squash = "Squash & stretch"
    case bounce = "Bounce"
    case blink = "Blink"
    case breathing = "Breathing"
    case float = "Float"
    case spin = "Spin"
    case goo = "Gooey blobs"
    case split = "Split & merge"
    case elastic = "Elastic"
    case shake = "Shake"
    case explosion = "Shape explosion"
    case particles = "Particles"
    case glow = "Glow"
    case neon = "Neon pulse"
    case ripple = "Ripple"
    case shockwave = "Shockwave"
    case trail = "Motion trail"
    case blur = "Animated blur"
    case distortion = "Warp distortion"
    case glitch = "Glitch"
    case waves = "Shader waves"
    case rotate3D = "3D rotation"
    case parallax = "Parallax drag"
    case gyroscope = "Gyroscope tilt"
    case gravity = "SpriteKit gravity"
    case collision = "SpriteKit collision"
    case spring = "Spring physics"
    case layers = "Depth layers"
    case reality = "RealityKit 3D sphere"
    case touch = "Tap reaction"
    case throwDrag = "Drag & throw"
    case tapBurst = "Tap burst"
    case hold = "Hold reaction"
    case microphone = "Microphone reactive"
    case sound = "Sound sync"
    case haptics = "Haptic pattern"
    case gestureMorph = "Gesture morph"

    var id: String { rawValue }

    var category: String {
        switch self {
        case .morph, .squash, .bounce, .blink, .breathing, .float,
             .spin, .goo, .split, .elastic, .shake, .explosion:
            return "AVATAR · 12"
        case .particles, .glow, .neon, .ripple, .shockwave, .trail,
             .blur, .distortion, .glitch, .waves:
            return "VISUAL FX · 10"
        case .rotate3D, .parallax, .gyroscope, .gravity,
             .collision, .spring, .layers, .reality:
            return "3D + PHYSICS · 8"
        default:
            return "INTERACTION · 8"
        }
    }

    var needsTouch: Bool {
        switch self {
        case .parallax, .touch, .throwDrag, .tapBurst, .hold, .gestureMorph, .microphone, .sound, .haptics:
            return true
        default: return false
        }
    }
}

private enum LabMode: String, CaseIterable {
    case showcase = "Showcase"
    case stress = "Stress"
    case system = "System"
    case compare = "Compare"
}

@MainActor
final class BloubAudioProbe: ObservableObject {
    @Published var level: CGFloat = 0
    @Published var status = "Mic off"
    private var recorder: AVAudioRecorder?
    private var meter: Timer?
    private var player: AVAudioPlayer?
    private var hapticEngine: CHHapticEngine?

    func microphoneOn() {
        AVAudioApplication.requestRecordPermission { [weak self] allowed in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard allowed else { self.status = "Microphone denied / unavailable"; return }
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
                    try session.setActive(true)
                    let path = FileManager.default.temporaryDirectory
                        .appendingPathComponent("bloub-meter.caf")
                    self.recorder = try AVAudioRecorder(url: path, settings: [
                        AVFormatIDKey: Int(kAudioFormatAppleIMA4),
                        AVSampleRateKey: 11025,
                        AVNumberOfChannelsKey: 1
                    ])
                    self.recorder?.isMeteringEnabled = true
                    self.recorder?.record()
                    self.status = "Real microphone · 10 Hz meter"
                    self.meter?.invalidate()
                    self.meter = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                        Task { @MainActor [weak self] in
                            guard let self, let recorder = self.recorder else { return }
                            recorder.updateMeters()
                            let dB = recorder.averagePower(forChannel: 0)
                            self.level = CGFloat(max(0, min(1, (dB + 55) / 50)))
                        }
                    }
                } catch { self.status = "Mic unavailable: \(error.localizedDescription)" }
            }
        }
    }

    func stop() {
        meter?.invalidate()
        meter = nil
        recorder?.stop()
        recorder = nil
        level = 0
        if status.hasPrefix("Real microphone") { status = "Mic off" }
    }

    func beep() {
        // Generate our own short PCM tone: no external music, asset or license.
        let rate = 22_050
        let count = Int(Double(rate) * 0.32)
        var pcm = [Int16](repeating: 0, count: count)
        for i in 0..<count {
            let time = Double(i) / Double(rate)
            let envelope = pow(max(0, 1 - time / 0.32), 2)
            pcm[i] = Int16(sin(time * Double.pi * 2 * 660) * envelope * 10_000)
        }
        var wave = Data()
        func u16(_ n: UInt16) { var v = n.littleEndian; withUnsafeBytes(of: &v) { wave.append(contentsOf: $0) } }
        func u32(_ n: UInt32) { var v = n.littleEndian; withUnsafeBytes(of: &v) { wave.append(contentsOf: $0) } }
        wave.append(contentsOf: Array("RIFF".utf8))
        u32(UInt32(36 + count * 2))
        wave.append(contentsOf: Array("WAVEfmt ".utf8))
        u32(16); u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16)
        wave.append(contentsOf: Array("data".utf8)); u32(UInt32(count * 2))
        for sample in pcm { u16(UInt16(bitPattern: sample)) }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            player = try AVAudioPlayer(data: wave)
            player?.play()
            status = "Original synthesized 660 Hz tone"
        } catch { status = "Audio playback unsupported" }
    }

    func haptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            status = "No haptics in this simulator (requires iPhone)"
            return
        }
        do {
            let events = (0..<4).map { index in
                CHHapticEvent(eventType: .hapticTransient,
                             parameters: [.init(parameterID: .hapticIntensity, value: Float(0.3 + Double(index) * 0.2))],
                             relativeTime: Double(index) * 0.13)
            }
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
            status = "Core Haptics · 4 pulses on device"
        } catch { status = "Haptics unavailable: \(error.localizedDescription)" }
    }
}

private final class BloubMotionSensor: ObservableObject {
    @Published var tilt: CGFloat = 0
    private let motion = CMMotionManager()
    private var timer: Timer?

    func start() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 25
        motion.startDeviceMotionUpdates()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 25, repeats: true) { [weak self] _ in
            guard let self, let data = self.motion.deviceMotion else { return }
            self.tilt = CGFloat(data.attitude.roll)
        }
    }
    func stop() { timer?.invalidate(); timer = nil; motion.stopDeviceMotionUpdates() }
}

@MainActor
final class BloubFPSProbe: ObservableObject {
    @Published var fps = 0
    @Published var dropped = 0
    @Published var temperature = "nominal"
    private var display: CADisplayLink?
    private var prior = 0.0
    private var accumulated = 0.0
    private var frames = 0

    func start() {
        guard display == nil else { return }
        prior = 0; accumulated = 0; frames = 0; dropped = 0
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        display = link
    }
    @objc private func tick(_ link: CADisplayLink) {
        if prior > 0 {
            let delta = link.timestamp - prior
            accumulated += delta
            frames += 1
            if delta > 1.0 / 27 { dropped += 1 }
            if accumulated >= 1 {
                fps = Int((Double(frames) / accumulated).rounded())
                temperature = {
                    switch ProcessInfo.processInfo.thermalState {
                    case .nominal: return "nominal"
                    case .fair: return "fair"
                    case .serious: return "serious"
                    case .critical: return "critical"
                    @unknown default: return "unknown"
                    }
                }()
                accumulated = 0; frames = 0
            }
        }
        prior = link.timestamp
    }
    func stop() { display?.invalidate(); display = nil; fps = 0 }
}

struct UltimateAnimationLab: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var lab: BloubLab
    @StateObject private var audio = BloubAudioProbe()
    @StateObject private var fps = BloubFPSProbe()
    @StateObject private var sensor = BloubMotionSensor()
    @State private var mode: LabMode = .showcase
    @State private var selected: BloubExperiment = .morph
    @State private var active = true
    @State private var intensity = 0.85
    @State private var count = 100.0
    @State private var burst = 0
    @State private var position = CGSize.zero
    @State private var hold = false
    @State private var touchCount = 0
    @State private var islandStyle = 0
    @State private var notificationFX = "glow"
    @State private var message = "Select any of the 38 experiments"

    private let groups = ["AVATAR · 12", "VISUAL FX · 10", "3D + PHYSICS · 8", "INTERACTION · 8"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("NATIVE iOS · ALL FX EXPERIMENT")
                        .font(.system(size: 10, design: .monospaced)).foregroundStyle(.cyan)
                    Text("38 effects · 4 test modes · iPhone 16 Pro target")
                        .font(.caption).foregroundStyle(.secondary)

                    Picker("Mode", selection: $mode) {
                        ForEach(LabMode.allCases, id: \.self) { value in
                            Text(value.rawValue).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("ultimate-mode-picker")

                    if mode == .system {
                        systemPanel
                    } else {
                        stagePanel
                        if mode == .compare {
                            comparePanel
                        } else {
                            controlsPanel
                        }
                        catalog
                    }
                    footer
                }
                .padding(15)
            }
            .background(Color(red: 0.025, green: 0.04, blue: 0.07).ignoresSafeArea())
            .navigationTitle("Bloub Ultimate Lab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("ultimate-close")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(active ? "Pause" : "Play") { active.toggle() }
                        .tint(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { fps.start() }
        .onDisappear { audio.stop(); sensor.stop(); fps.stop() }
        .onChange(of: selected) { _, selection in
            audio.stop()
            sensor.stop()
            position = .zero
            burst += 1
            if selection == .gyroscope { sensor.start() }
            message = "Testing: \(selection.rawValue)"
        }
    }

    private var stagePanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(mode == .stress ? "STRESS · combined" : selected.rawValue).font(.headline)
                Spacer()
                Text("LIVE").font(.caption2.monospaced()).foregroundStyle(active ? .green : .orange)
            }
            if selected == .reality && mode != .stress {
                RealityBallStage()
                    .frame(height: 270)
                    .background(.black, in: RoundedRectangle(cornerRadius: 14))
            } else if (selected == .gravity || selected == .collision) && mode != .stress {
                PhysicsBallStage(collision: selected == .collision, reset: burst)
                    .frame(height: 270)
                    .background(.black, in: RoundedRectangle(cornerRadius: 14))
            } else {
                TimelineView(.animation(minimumInterval: mode == .stress ? 1.0 / 60 : 1.0 / 30, paused: !active)) { context in
                    BloubMotionStage(
                        experiment: mode == .stress ? .particles : selected,
                        timestamp: context.date.timeIntervalSinceReferenceDate,
                        strength: intensity,
                        particles: Int(count),
                        stress: mode == .stress,
                        burst: burst,
                        touchOffset: position,
                        holding: hold,
                        audioLevel: audio.level,
                        tilt: sensor.tilt
                    )
                }
                .frame(height: 270)
                .clipped()
                .background(.black, in: RoundedRectangle(cornerRadius: 14))
                .contentShape(Rectangle())
                .simultaneousGesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        position = value.translation
                        if selected == .gestureMorph { burst = min(23, Int(abs(value.translation.width) / 7)) }
                    }
                    .onEnded { _ in
                        withAnimation(.interpolatingSpring(stiffness: 170, damping: 9)) { position = .zero }
                        if selected == .throwDrag || selected == .tapBurst || selected == .touch { burst += 1 }
                    })
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.3)
                    .onEnded { _ in hold.toggle(); burst += 1 })
                .onTapGesture { touchCount += 1; burst += 1 }
            }
            HStack(spacing: 12) {
                Label("\(fps.fps) FPS", systemImage: "speedometer")
                Text("Long gaps: \(fps.dropped)")
                Spacer()
                Text("Thermal: \(fps.temperature)")
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(.cyan)
            Text(message).font(.caption2).foregroundStyle(.secondary)
                .accessibilityIdentifier("ultimate-status")
        }
        .padding(12)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16))
    }

    private var controlsPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("Intensity").font(.caption)
                Slider(value: $intensity, in: 0.1...1.8)
            }
            HStack {
                Text("Particles").font(.caption)
                Slider(value: $count, in: 20...600, step: 20)
                Text("\(Int(count))").font(.caption.monospacedDigit())
            }
            HStack {
                Button("Trigger / Burst") { burst += 1 }
                Button("Reset") { position = .zero; hold = false; burst += 1 }
                Button("Next FX") {
                    let options = BloubExperiment.allCases
                    selected = options[(options.firstIndex(of: selected)! + 1) % options.count]
                }
            }
            .buttonStyle(.bordered)
            .font(.caption)
            if selected == .microphone {
                HStack {
                    Button("Mic ON") { audio.microphoneOn() }
                    Button("Mic OFF") { audio.stop() }
                    Text("\(Int(audio.level * 100))%").monospacedDigit()
                }
                .buttonStyle(.bordered)
                Text(audio.status).font(.caption2)
            }
            if selected == .sound || selected == .haptics {
                HStack {
                    Button("SOUND") { audio.beep(); burst += 1 }
                    Button("HAPTIC") { audio.haptic(); burst += 1 }
                }
                .buttonStyle(.bordered)
                Text(audio.status).font(.caption2)
            }
            if selected.needsTouch {
                Text("Tap, hold and drag directly on the stage. Device-only sensors may not work in Appetize.")
                    .font(.caption2).foregroundStyle(.orange)
            }
        }
    }

    private var catalog: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(groups, id: \.self) { category in
                VStack(alignment: .leading, spacing: 8) {
                    Text(category).font(.caption.monospaced().bold()).foregroundStyle(.cyan)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 7) {
                        ForEach(BloubExperiment.allCases.filter { $0.category == category }) { effect in
                            Button {
                                selected = effect
                                mode = .showcase
                            } label: {
                                Text(effect.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                                    .frame(maxWidth: .infinity, minHeight: 32)
                                    .foregroundStyle(selected == effect ? .black : .white)
                                    .background(selected == effect ? Color.cyan : Color.white.opacity(0.095),
                                                in: RoundedRectangle(cornerRadius: 9))
                            }
                            .accessibilityIdentifier("ultimate-effect-\(effect.id)")
                        }
                    }
                }
            }
        }
    }

    private var comparePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("A/B: Native sprite vs mathematical FX").font(.caption.weight(.semibold))
            HStack {
                TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !active)) { t in
                    BloubMotionStage(experiment: .morph, timestamp: t.date.timeIntervalSinceReferenceDate,
                                     strength: intensity, particles: 40, stress: false,
                                     burst: burst, touchOffset: .zero, holding: false, audioLevel: 0, tilt: 0)
                }
                TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !active)) { t in
                    BloubMotionStage(experiment: selected, timestamp: t.date.timeIntervalSinceReferenceDate,
                                     strength: intensity, particles: 40, stress: false,
                                     burst: burst, touchOffset: .zero, holding: false, audioLevel: 0, tilt: 0)
                }
            }
            .frame(height: 150)
            .clipped()
            Text("Left: original 24-frame sprite · Right: selected technique")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var systemPanel: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("SYSTEM SURFACES · Apple controls the presentation")
                .font(.caption.monospaced().bold()).foregroundStyle(.orange)
            Text("Dynamic Island: Compact / Minimal / Expanded · Lock Screen · StandBy")
                .font(.caption2)
            HStack {
                Button("Start Island") { lab.start() }
                Button("Next style \(islandStyle + 1)/6") {
                    islandStyle = (islandStyle + 1) % 6
                    lab.cycleIslandStyle(islandStyle)
                }
            }.buttonStyle(.bordered)
            HStack {
                Button("Next pose") { lab.nextIslandPose() }
                Button("+20%") { lab.advance() }
                Button("Alert") { lab.attention() }
            }.buttonStyle(.bordered)
            Button("24-frame Island morph (10s delay)") {
                lab.morphInTwoSecondsAfterTenSeconds()
            }.buttonStyle(.bordered)
            Button("5-pose Island parade (10s delay)") {
                lab.poseParadeAfterTenSeconds()
            }.buttonStyle(.bordered)
            Text("Notification theater · long-press the banner to expand:")
                .font(.caption.weight(.medium))
            Picker("Notification FX", selection: $notificationFX) {
                ForEach(["glow", "spin", "shake", "pulse", "ripple", "glitch", "morph"], id: \.self) {
                    Text($0.capitalized).tag($0)
                }
            }
            .pickerStyle(.menu)
            Button("Schedule selected notification (10s)") {
                lab.sendBanner(delay: 10, morph: notificationFX == "morph", effect: notificationFX)
            }
            .buttonStyle(.borderedProminent)
            Text(lab.message).font(.caption2).foregroundStyle(.secondary)
            Divider()
            Text("HOME/LOCK WIDGETS").font(.caption.monospaced().bold()).foregroundStyle(.cyan)
            Text("Long-press Home → Edit → Add Widget → Bloub. On Lock Screen choose Bloub circular/rectangular. Widget timelines are system-scheduled, NOT full-time loops.")
                .font(.caption2)
            Text("CONTROL CENTER / ACTION BUTTON").font(.caption.monospaced().bold()).foregroundStyle(.cyan)
            Text("On iOS 18+, add Bloub Lab from Control Center → Add Control, or map it to the Action Button in Settings. This launches Bloub; iOS controls the icon animation.")
                .font(.caption2).foregroundStyle(.orange)
            Text("Live Activities use iOS-owned transitions (max ~2s). Dynamic Island cannot be forced to display 24 individual frames. Reduced-luminance Always-On can suppress animation.")
                .font(.caption2).foregroundStyle(.orange)
            Button("End Live Activity") { lab.finish() }.buttonStyle(.bordered)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 15))
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("TEST NOTES").font(.caption.monospaced().bold())
            Text("Continuous effects run in the foreground app; pause stops TimelineView. Audio/haptics/sensors need real-device permissions. Simulator lag may be Appetize streaming, not native FPS. No AI agents are connected.")
                .font(.caption2).foregroundStyle(.secondary)
            Text("FPS probe measures app CADisplayLink frames; 'Long gaps' counts frames spaced over 37ms (not a GPU profiler).")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }
}

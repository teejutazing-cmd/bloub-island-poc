import SwiftUI
import ActivityKit
import UserNotifications
import UIKit

// All actions in this app are local simulations. No backend, APNs, or real agent connection.
final class LabNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LabNotificationDelegate()

    func configure() {
        let open = UNNotificationAction(identifier: "BLOUB_OPEN", title: "Open Bloub", options: [.foreground])
        let ignore = UNNotificationAction(identifier: "BLOUB_DISMISS", title: "Dismiss", options: [])
        UNUserNotificationCenter.current().setNotificationCategories([
            UNNotificationCategory(identifier: "BLOUB_DEMO", actions: [open, ignore], intentIdentifiers: [])
        ])
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}

@MainActor
final class BloubLab: ObservableObject {
    @Published var message = "Ready for an offline experiment"
    @Published var mood: BloubMood = .working
    @Published var progress = 10
    @Published var pose = 0
    @Published var morphFrame = -1
    @Published var running = false
    @Published var notificationsAllowed = false
    @Published var attentionCountdown = 0
    @Published var islandStyle = 0

    private var activity: Activity<BloubAttributes>?
    private var pendingAttention: Task<Void, Never>?
    private var backgroundAttentionID: UIBackgroundTaskIdentifier = .invalid

    init() {
        activity = Activity<BloubAttributes>.activities.first
        if let activity {
            running = true
            progress = activity.content.state.progress
            mood = BloubMood(rawValue: activity.content.state.mood) ?? .working
            pose = activity.content.state.pose
            morphFrame = activity.content.state.morphFrame
            message = "Live Activity resumed"
        }
    }

    private func makeContent() -> ActivityContent<BloubAttributes.ContentState> {
        ActivityContent(
            state: BloubAttributes.ContentState(
                phase: mood.title,
                progress: progress,
                mood: mood.rawValue,
                detail: mood == .approval ? "Your decision needed" :
                        mood == .error ? "Something needs attention" :
                        mood == .recent ? "Task finished" :
                        "Offline simulation",
                pose: pose,
                morphFrame: morphFrame,
                animationStyle: islandStyle
            ),
            staleDate: nil,
            relevanceScore: mood == .approval || mood == .error ? 100 : 50
        )
    }

    func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            message = "Enable Live Activities in Settings > Bloub"
            return
        }
        guard !running else {
            message = "Live Activity is already running"
            return
        }
        progress = 10
        morphFrame = -1
        do {
            activity = try Activity<BloubAttributes>.request(
                attributes: BloubAttributes(agentName: "Bloub"),
                content: makeContent(),
                pushType: nil
            )
            running = true
            message = "Started — lock iPhone or long-press the Island"
        } catch {
            message = "Start failed: \(error.localizedDescription)"
        }
    }

    func choose(_ selection: BloubMood) {
        mood = selection
        pose = (pose + 1) % 5
        morphFrame = -1
        message = "\(selection.title) · pose \(pose) selected"
        if running { refresh() }
    }

    // Six legal state-change presentations; iOS controls actual Island transitions.
    func cycleIslandStyle(_ style: Int) {
        islandStyle = max(0, min(5, style))
        if !running { start() }
        guard running else { return }
        pose = (pose + 1) % 5
        progress = min(100, 10 + islandStyle * 18)
        morphFrame = -1
        message = "Island transition style \(islandStyle + 1)/6 sent; iOS owns timing"
        refresh()
    }

    func nextIslandPose() {
        if !running { start() }
        guard running else { return }
        pose = (pose + 1) % 5
        morphFrame = -1
        message = "Sent avatar pose \(pose) to Island / Lock Screen"
        refresh()
    }

    func advance() {
        if !running { start(); return }
        progress = progress >= 100 ? 10 : min(progress + 20, 100)
        pose = (pose + 1) % 5
        morphFrame = -1
        message = "Progress: \(progress)% · avatar pose \(pose)"
        refresh()
    }

    func refresh(alert: Bool = false) {
        guard let activity else { message = "Start Live Activity first"; return }
        let payload = makeContent()
        let config: AlertConfiguration? = alert
            ? AlertConfiguration(title: "Bloub needs attention",
                body: "Live Activity expanded alert demo", sound: .default)
            : nil
        Task {
            await activity.update(payload, alertConfiguration: config)
            if alert {
                message = "Island alert sent — iOS decides presentation"
                releaseBackgroundAttention()
            }
        }
    }

    private func releaseBackgroundAttention() {
        guard backgroundAttentionID != .invalid else { return }
        let id = backgroundAttentionID
        backgroundAttentionID = .invalid
        UIApplication.shared.endBackgroundTask(id)
    }

    private func cancelScheduledAttention() {
        pendingAttention?.cancel()
        pendingAttention = nil
        attentionCountdown = 0
        releaseBackgroundAttention()
    }

    // A short, user-triggered background execution window lets you swipe Home
    // before this local ActivityKit update. It is NOT a durable scheduler.
    func attentionAfterTenSeconds() {
        cancelScheduledAttention()
        if !running { start() }
        guard activity != nil else { return }

        mood = .working
        pose = 1
        morphFrame = -1
        refresh()
        attentionCountdown = 10
        message = "10 seconds: swipe to Home now, then watch the Island"

        backgroundAttentionID = UIApplication.shared.beginBackgroundTask(
            withName: "BloubIslandDelayedAttention",
            expirationHandler: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.pendingAttention?.cancel()
                    self.pendingAttention = nil
                    self.attentionCountdown = 0
                    self.message = "iOS background time expired before alert"
                    self.releaseBackgroundAttention()
                }
            }
        )

        pendingAttention = Task { [weak self] in
            for remaining in stride(from: 9, through: 0, by: -1) {
                do { try await Task.sleep(for: .seconds(1)) }
                catch { return }
                guard let self, !Task.isCancelled else { return }
                self.attentionCountdown = remaining
            }
            guard let self, !Task.isCancelled else { return }
            self.mood = .approval
            self.pose = 4
            self.pendingAttention = nil
            self.refresh(alert: true)
        }
    }

    func poseParadeAfterTenSeconds() {
        cancelScheduledAttention()
        if !running { start() }
        guard let activity else { return }
        mood = .working
        pose = 0
        morphFrame = -1
        refresh()
        attentionCountdown = 10
        message = "Pose parade starts in 10 seconds — swipe Home now"

        // This is a best-effort short background experiment, not a persistent loop.
        backgroundAttentionID = UIApplication.shared.beginBackgroundTask(
            withName: "BloubIslandPoseParade",
            expirationHandler: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.pendingAttention?.cancel()
                    self.pendingAttention = nil
                    self.attentionCountdown = 0
                    self.message = "iOS ended the short background test"
                    self.releaseBackgroundAttention()
                }
            }
        )
        pendingAttention = Task { [weak self] in
            for remaining in stride(from: 9, through: 0, by: -1) {
                do { try await Task.sleep(for: .seconds(1)) }
                catch { return }
                guard let self, !Task.isCancelled else { return }
                self.attentionCountdown = remaining
            }
            guard let self, !Task.isCancelled else { return }
            for next in [1, 2, 3, 4, 0] {
                guard !Task.isCancelled else { break }
                self.pose = next
                await activity.update(self.makeContent())
                do { try await Task.sleep(for: .milliseconds(900)) }
                catch { break }
            }
            self.pendingAttention = nil
            self.message = "Sent 5 discrete Island poses; iOS may coalesce updates"
            self.releaseBackgroundAttention()
        }
    }

    // ATTEMPT a 24-frame ORIGINAL sprite animation on the real Dynamic Island.
    // Live Activity refreshes are controlled/coalesced by iOS; requesting 12 FPS
    // does NOT guarantee that the system renders all 24 frames.
    func morphInTwoSecondsAfterTenSeconds() {
        cancelScheduledAttention()
        if !running { start() }
        guard let activity else { return }
        mood = .working
        pose = 0
        morphFrame = 0
        refresh()
        attentionCountdown = 10
        message = "Circle → triangle: 24 original frames in 10s. Swipe Home now."

        backgroundAttentionID = UIApplication.shared.beginBackgroundTask(
            withName: "BloubOriginalSpriteMorph2s",
            expirationHandler: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.pendingAttention?.cancel()
                    self.pendingAttention = nil
                    self.attentionCountdown = 0
                    self.message = "iOS ended the background morph before completion"
                    self.releaseBackgroundAttention()
                }
            }
        )
        pendingAttention = Task { [weak self] in
            for remaining in stride(from: 9, through: 0, by: -1) {
                do { try await Task.sleep(for: .seconds(1)) }
                catch { return }
                guard let self, !Task.isCancelled else { return }
                self.attentionCountdown = remaining
            }
            guard let self, !Task.isCancelled else { return }

            // Frame data is precompiled in the WidgetKit asset catalog (0...23).
            // Each is taken unchanged from the source Bloub-04 working sprite.
            for frame in 0..<24 {
                guard !Task.isCancelled else { break }
                self.morphFrame = frame
                await activity.update(self.makeContent())
                if frame < 23 {
                    do { try await Task.sleep(for: .milliseconds(83)) }
                    catch { break }
                }
            }
            self.pendingAttention = nil
            self.message = "24 frames requested; Island may show fewer (iOS coalescing)"
            self.releaseBackgroundAttention()
        }
    }

    func attention() {
        cancelScheduledAttention()
        if !running { start() }
        guard running else { return }
        mood = .approval
        pose = 4
        morphFrame = -1
        refresh(alert: true)
    }

    func finish() {
        cancelScheduledAttention()
        guard let activity else { message = "No active activity"; return }
        let content = makeContent()
        Task {
            await activity.end(content, dismissalPolicy: .immediate)
            self.activity = nil
            running = false
            message = "Live Activity ended"
        }
    }

    func requestNotifications() {
        Task {
            do {
                notificationsAllowed = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
                message = notificationsAllowed ? "Notifications enabled" : "Notifications denied in Settings"
            } catch {
                message = "Notification permission: \(error.localizedDescription)"
            }
        }
    }

    func sendBanner(delay: TimeInterval = 2, morph: Bool = false, effect: String = "default") {
        Task {
            let center = UNUserNotificationCenter.current()
            let approved: Bool
            do {
                approved = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                message = "Notifications unavailable: \(error.localizedDescription)"
                return
            }
            guard approved else { message = "Allow notifications in Settings > Bloub"; return }
            notificationsAllowed = true
            let content = UNMutableNotificationContent()
            content.title = morph ? "Bloub · Circle → Triangle" : "Bloub · \(mood.title)"
            content.subtitle = morph ? "24 original frames · 2 seconds" : "Offline agent preview"
            content.body = mood == .approval
                ? "A simulated worker needs your approval."
                : "Bloub has an update. Open the notification to inspect."
            content.sound = .default
            content.categoryIdentifier = "BLOUB_DEMO"
            content.userInfo = ["bloubMood": morph ? "working" : mood.rawValue,
                                "bloubMorph": morph,
                                "bloubFX": effect]

            // Add a real Bloub avatar image for expanded notification previews.
            if let image = Bundle.main.url(forResource: "bloub-notification", withExtension: "png") {
                let path = FileManager.default.temporaryDirectory
                    .appendingPathComponent("bloub-preview-\(UUID().uuidString).png")
                do {
                    try FileManager.default.copyItem(at: image, to: path)
                    content.attachments = [try UNNotificationAttachment(identifier: "Bloub Avatar", url: path)]
                } catch {
                    // Notification still works without an attachment.
                }
            }
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            )
            do {
                try await center.add(request)
                message = "Local notification scheduled in \(Int(delay)) seconds"
            } catch {
                message = "Notification failed: \(error.localizedDescription)"
            }
        }
    }
}

private struct BloubMotion: View {
    let mood: BloubMood
    @State private var floatUp = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 12.0)) { timeline in
            let frame = (Int(timeline.date.timeIntervalSinceReferenceDate * 12) % 144 + 144) % 144
            ZStack {
                Circle()
                    .fill(mood.accent.opacity(0.22))
                    .frame(width: 180, height: 180)
                    .blur(radius: 32)
                SpriteFrame(mood: mood, frameIndex: frame)
                    .frame(width: 190, height: 190)
                    .offset(y: floatUp ? -7 : 7)
                    .rotation3DEffect(.degrees(floatUp ? 7 : -7), axis: (x: 0.8, y: 1, z: 0))
                Text("SPRITE FRAME \(frame + 1) / 144")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.cyan)
                    .offset(y: 105)
            }
        }
        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: floatUp)
        .onAppear { floatUp = true }
        .accessibilityLabel("Animated Bloub \(mood.title)")
    }
}

private struct SpriteFrame: View {
    let mood: BloubMood
    let frameIndex: Int

    var body: some View {
        Group {
            if let sheet = UIImage(named: "bloub-sheet-\(mood.rawValue)"),
               let rawImage = sheet.cgImage,
               let cropped = rawImage.cropping(to: CGRect(x: frameIndex * 64, y: 0, width: 64, height: 64)) {
                Image(uiImage: UIImage(cgImage: cropped))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                BloubStill(mood: mood, size: 150)
            }
        }
    }
}

private struct LabPanel<Content: View>: View {
    let heading: String
    let info: String
    let content: Content

    init(heading: String, info: String, @ViewBuilder content: () -> Content) {
        self.heading = heading
        self.info = info
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(heading).font(.headline)
            Text(info).font(.caption).foregroundStyle(.secondary)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct LabButton: View {
    let label: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 40)
        }
        .buttonStyle(.bordered)
        .tint(.cyan)
    }
}

struct ControlView: View {
    @StateObject private var lab = BloubLab()
    @State private var ultimateOpen = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 4) {
                        Text("BLOUB / LAB").font(.caption.monospaced().weight(.bold))
                            .tracking(3).foregroundStyle(.cyan)
                        Text("Avatar playground").font(.largeTitle.weight(.bold))
                        Text("100% offline · no agent connections")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 5) {
                        BloubMotion(mood: lab.mood)
                            .frame(height: 205)
                        Label(lab.mood.title, systemImage: lab.mood.symbol)
                            .foregroundStyle(lab.mood.accent)
                            .font(.title3.weight(.bold))
                        Text(lab.message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .frame(minHeight: 28)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 25))

                    Button {
                        ultimateOpen = true
                    } label: {
                        VStack(spacing: 5) {
                            Label("OPEN BLOUB ULTIMATE ANIMATION LAB", systemImage: "wand.and.stars")
                                .font(.headline)
                            Text("38 native experiments · 4 modes · shaders · physics · 3D · System UI")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity, minHeight: 64)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .accessibilityIdentifier("ultimate-open")

                    LabPanel(heading: "01 · Avatar states", info: "Original Bloub 04 sprite animation · 6 local moods") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 10) {
                            ForEach(BloubMood.allCases) { choice in
                                Button { lab.choose(choice) } label: {
                                    VStack(spacing: 5) {
                                        BloubStill(mood: choice, size: 48)
                                        Text(choice.title).font(.caption2.weight(.medium))
                                    }
                                    .foregroundStyle(lab.mood == choice ? choice.accent : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        lab.mood == choice ? choice.accent.opacity(0.13) : Color.white.opacity(0.045),
                                        in: RoundedRectangle(cornerRadius: 13)
                                    )
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    LabPanel(heading: "02 · Dynamic Island", info: "Compact · Expanded · Minimal · Live Activity alert") {
                        HStack {
                            LabButton(label: "Start", symbol: "play.fill") { lab.start() }
                            LabButton(label: "+20%", symbol: "plus.circle") { lab.advance() }
                        }
                        LabButton(label: "NEXT Bloub pose on Island", symbol: "figure.dance") {
                            lab.nextIslandPose()
                        }
                        LabButton(label: "24-FRAME MORPH / 2s · Go Home in 10s", symbol: "sparkles") {
                            lab.morphInTwoSecondsAfterTenSeconds()
                        }
                        LabButton(label: "5-pose Island parade in 10s", symbol: "play.rectangle.on.rectangle") {
                            lab.poseParadeAfterTenSeconds()
                        }
                        LabButton(label: "Island alert in 10s · Go Home", symbol: "timer") {
                            lab.attentionAfterTenSeconds()
                        }
                        if lab.attentionCountdown > 0 {
                            Text("Alert in \(lab.attentionCountdown)s — swipe up to Home now")
                                .font(.subheadline.monospacedDigit().weight(.bold))
                                .foregroundStyle(.orange)
                        }
                        LabButton(label: "Instant alert (comparison)", symbol: "exclamationmark.bubble.fill") {
                            lab.attention()
                        }
                        LabButton(label: "Stop Live Activity", symbol: "stop.fill") {
                            lab.finish()
                        }
                        ProgressView(value: Double(lab.progress), total: 100)
                            .tint(lab.mood.accent)
                        Text("24-FRAME MORPH sends the original circle-to-triangle frames over 2 seconds, after a 10-second delay. iOS may merge rapid Live Activity updates. The expanded morph notification plays the complete 24-frame sequence locally.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }

                    LabPanel(heading: "03 · ANIMATED notification", info: "Long-press the delivered banner to open Bloub's animated custom notification view") {
                        LabButton(label: "Enable Notifications", symbol: "bell.badge") {
                            lab.requestNotifications()
                        }
                        LabButton(label: "MORPH notification · 24 frames / 2s", symbol: "film.stack") {
                            lab.sendBanner(delay: 10, morph: true)
                        }
                        LabButton(label: "Banner in 10s · Go Home", symbol: "timer") {
                            lab.sendBanner(delay: 10)
                        }
                        LabButton(label: "Instant banner (2s)", symbol: "paperplane.fill") {
                            lab.sendBanner()
                        }
                        Text("For a guaranteed 2-second sprite playback test, tap MORPH notification, swipe Home, then LONG-PRESS the delivered banner. The compact banner cannot run custom frame animations.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }

                    LabPanel(heading: "04 · Lock Screen + Home", info: "Native Live Activity and Home / Lock Screen widgets") {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.iphone")
                            Text("Start Live Activity → lock the iPhone → check Lock Screen")
                        }
                        .font(.caption)
                        HStack(spacing: 10) {
                            Image(systemName: "square.grid.2x2")
                            Text("Long-press Home Screen → Edit → Add Widget → Bloub")
                        }
                        .font(.caption)
                        Text("Home/Lock Widgets rotate snapshots on a slow timeline. The Live Activity changes discrete poses when updated; no widget sprite loop is permitted.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 38)
            }
            .background(
                LinearGradient(colors: [Color(red: 0.035, green: 0.07, blue: 0.12), .black],
                    startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            )
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $ultimateOpen) {
            UltimateAnimationLab(lab: lab)
        }
        .onAppear {
            #if targetEnvironment(simulator)
            // Optional CI-only native simulator smoke test. Never runs on iPhone.
            if ProcessInfo.processInfo.arguments.contains("--bloub-sim-morph") {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1))
                    lab.morphInTwoSecondsAfterTenSeconds()
                }
            }
            #endif
        }
    }
}

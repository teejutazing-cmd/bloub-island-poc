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
        // This test build is Island-first. Never auto-present legacy in-app banners.
        completionHandler([])
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
    @Published var islandAlertStage = 0
    @Published var islandAlertTick = 0

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
            islandAlertStage = activity.content.state.islandAlertStage ?? 0
            islandAlertTick = activity.content.state.islandAlertTick ?? 0
            message = "Live Activity resumed"
        }
    }

    private func makeContent() -> ActivityContent<BloubAttributes.ContentState> {
        ActivityContent(
            state: BloubAttributes.ContentState(
                phase: islandAlertStage == 2 ? "ATTENTION" : mood.title,
                progress: progress,
                mood: mood.rawValue,
                detail: mood == .approval ? "Your decision needed" :
                        mood == .error ? "Something needs attention" :
                        mood == .recent ? "Task finished" :
                        "Offline simulation",
                pose: pose,
                morphFrame: morphFrame,
                animationStyle: islandStyle,
                islandAlertStage: islandAlertStage,
                islandAlertTick: islandAlertTick
            ),
            staleDate: Date.now.addingTimeInterval(90),
            relevanceScore: islandAlertStage == 2 ? 100 :
                            mood == .approval || mood == .error ? 90 : 50
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
        islandAlertStage = 0
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
        // Apple documents an alertConfiguration update as the supported path
        // for requesting an Expanded Live Activity in Dynamic Island. This is
        // not a UNNotification banner. iOS still chooses the presentation.
        let config: AlertConfiguration? = alert
            ? AlertConfiguration(title: "Bloub · Dynamic Island alert",
                body: "Check the expanded Bloub Live Activity", sound: .default)
            : nil
        Task {
            await activity.update(payload, alertConfiguration: config)
            if alert {
                message = "Island alert sent — iOS decides presentation"
                releaseBackgroundAttention()
            }
        }
    }

    // PRIMARY outside-app test. Start the Activity while foregrounded, then
    // swipe Home; an ActivityKit alert update follows after 8 seconds.
    // No UNNotificationRequest is scheduled, so there is no standard banner.
    func islandPopupAfterEightSeconds(_ outcome: BloubMood) {
        // Clear older demo banners so only the Island update is observed.
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        cancelScheduledAttention()
        if !running { start() }
        guard activity != nil else { return }

        mood = .working
        progress = 45
        pose = 0
        morphFrame = -1
        islandAlertStage = 1
        islandAlertTick += 1
        refresh()
        attentionCountdown = 8
        message = "ISLAND ONLY · swipe Home now. Live Activity alert in 8 seconds."

        backgroundAttentionID = UIApplication.shared.beginBackgroundTask(
            withName: "BloubExpandedIslandAlert",
            expirationHandler: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.pendingAttention?.cancel()
                    self.pendingAttention = nil
                    self.attentionCountdown = 0
                    self.message = "iOS ended background time; retry and swipe Home earlier"
                    self.releaseBackgroundAttention()
                }
            }
        )
        pendingAttention = Task { [weak self] in
            for remaining in stride(from: 7, through: 0, by: -1) {
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                guard let self, !Task.isCancelled else { return }
                self.attentionCountdown = remaining
            }
            guard let self, !Task.isCancelled else { return }
            self.mood = outcome
            self.pose = outcome == .approval ? 4 : outcome == .error ? 3 : 2
            self.progress = outcome == .recent ? 100 : 80
            self.islandAlertStage = outcome == .recent ? 3 : 2
            self.islandAlertTick += 1
            self.pendingAttention = nil
            self.refresh(alert: true)
            self.message = "Sent ActivityKit ALERT; check Dynamic Island (not banner)"
        }
    }

    // Control group: identical activity update with NO AlertConfiguration.
    // Helps distinguish Island's normal content refresh from the true popup.
    func islandSilentAfterEightSeconds() {
        cancelScheduledAttention()
        if !running { start() }
        guard activity != nil else { return }
        mood = .working
        pose = 0
        progress = 40
        morphFrame = -1
        islandAlertStage = 1
        islandAlertTick += 1
        refresh()
        attentionCountdown = 8
        message = "SILENT CONTROL · swipe Home. Only pose/progress should update."
        backgroundAttentionID = UIApplication.shared.beginBackgroundTask(
            withName: "BloubSilentIslandControl",
            expirationHandler: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.pendingAttention?.cancel()
                    self.pendingAttention = nil
                    self.attentionCountdown = 0
                    self.releaseBackgroundAttention()
                }
            }
        )
        pendingAttention = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(8)) } catch { return }
            guard let self, !Task.isCancelled else { return }
            self.mood = .recent
            self.pose = 2
            self.progress = 100
            self.islandAlertStage = 3
            self.islandAlertTick += 1
            self.pendingAttention = nil
            self.refresh(alert: false)
            self.releaseBackgroundAttention()
            self.message = "Silent ActivityKit update sent; should NOT request popup"
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    HStack(spacing: 12) {
                        BloubStill(mood: lab.mood, size: 48, frame: lab.pose)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("BLOUB / ISLAND ONLY")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(.cyan)
                            Text("Dynamic Island Alert Lab")
                                .font(.title2.bold())
                        }
                    }
                    Text("OUTSIDE APP · iPhone 16 Pro · ActivityKit")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Test a popup from the Dynamic Island itself — NOT a notification banner.")
                        .font(.subheadline.weight(.medium))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle().fill(lab.running ? .green : .orange)
                                .frame(width: 9, height: 9)
                            Text(lab.running ? "Live Activity active" : "Live Activity not started")
                                .font(.caption.bold())
                            Spacer()
                            Text("ISLAND").font(.caption2.monospaced())
                        }
                        Button {
                            lab.start()
                        } label: {
                            Label("START ISLAND", systemImage: "play.fill")
                                .frame(maxWidth: .infinity, minHeight: 46)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("island-start")
                    }
                    .padding(14)
                    .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("01 · EXPAND FROM DYNAMIC ISLAND")
                            .font(.caption.monospaced().bold())
                            .foregroundStyle(.orange)
                        Text("Tap one test and immediately swipe Home. After 8 seconds the app sends an ActivityKit Live Activity alert with sound. It does not schedule UNNotification.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        islandButton("⚠️ APPROVAL POPUP · 8s", symbol: "exclamationmark.circle.fill",
                                     id: "island-alert-approval", color: .orange) {
                            lab.islandPopupAfterEightSeconds(.approval)
                        }
                        islandButton("🔴 ERROR POPUP · 8s", symbol: "xmark.octagon.fill",
                                     id: "island-alert-error", color: .red) {
                            lab.islandPopupAfterEightSeconds(.error)
                        }
                        islandButton("✅ COMPLETED POPUP · 8s", symbol: "checkmark.circle.fill",
                                     id: "island-alert-complete", color: .green) {
                            lab.islandPopupAfterEightSeconds(.recent)
                        }
                        if lab.attentionCountdown > 0 {
                            Text("SWIPE HOME NOW · \(lab.attentionCountdown) SECONDS")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(.orange)
                                .accessibilityIdentifier("island-countdown")
                        }
                    }
                    .padding(14)
                    .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 9) {
                        Text("02 · COMPARE SYSTEM BEHAVIOR")
                            .font(.caption.monospaced().bold())
                            .foregroundStyle(.cyan)
                        islandButton("SILENT ISLAND UPDATE · 8s", symbol: "waveform.path",
                                     id: "island-alert-silent", color: .cyan) {
                            lab.islandSilentAfterEightSeconds()
                        }
                        Text("Silent control only updates the pose/progress; no popup is requested.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        islandButton("INSTANT ACTIVITYKIT ALERT", symbol: "bolt.circle.fill",
                                     id: "island-alert-immediate", color: .orange) {
                            lab.attention()
                        }
                        islandButton("MORPH FRAMES · 10s", symbol: "circle.hexagongrid.fill",
                                     id: "island-frames", color: .purple) {
                            lab.morphInTwoSecondsAfterTenSeconds()
                        }
                        Text("Morph sends discrete sprite states; iOS may coalesce them. It is not a 12fps video.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ACTIVITYKIT STATUS").font(.caption.monospaced().bold())
                        Text(lab.message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("island-status")
                        Button("END LIVE ACTIVITY") { lab.finish() }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("island-end")
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16))

                    Text("iOS decides if/when the expanded Island appears. Allow Live Activities and sound in Settings. For genuine tests, record the screen while outside the app.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
            }
            .background(Color(red: 0.025, green: 0.035, blue: 0.065).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            #if targetEnvironment(simulator)
            if ProcessInfo.processInfo.arguments.contains("--bloub-sim-island-popup") {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1))
                    lab.islandPopupAfterEightSeconds(.approval)
                }
            }
            #endif
        }
    }

    private func islandButton(
        _ title: String,
        symbol: String,
        id: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 46)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
        .accessibilityIdentifier(id)
    }
}

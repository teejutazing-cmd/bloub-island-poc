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
    @Published var running = false
    @Published var notificationsAllowed = false

    private var activity: Activity<BloubAttributes>?

    init() {
        activity = Activity<BloubAttributes>.activities.first
        if let activity {
            running = true
            progress = activity.content.state.progress
            mood = BloubMood(rawValue: activity.content.state.mood) ?? .working
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
                        "Offline simulation"
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
        message = "\(selection.title) avatar selected"
        if running { refresh() }
    }

    func advance() {
        if !running { start(); return }
        progress = progress >= 100 ? 10 : min(progress + 20, 100)
        message = "Progress: \(progress)%"
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
            if alert { message = "Island alert sent — iOS decides presentation" }
        }
    }

    func attention() {
        if !running { start() }
        mood = .approval
        refresh(alert: true)
    }

    func finish() {
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

    func sendBanner() {
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
            content.title = "Bloub · \(mood.title)"
            content.subtitle = "Offline agent preview"
            content.body = mood == .approval
                ? "A simulated worker needs your approval."
                : "Bloub has an update. Open the notification to inspect."
            content.sound = .default
            content.categoryIdentifier = "BLOUB_DEMO"

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
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
            )
            do {
                try await center.add(request)
                message = "Local banner scheduled in 2 seconds"
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
        TimelineView(.animation(minimumInterval: 1.0 / 12.0)) { timeline in
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
                        LabButton(label: "Attention / big alert", symbol: "exclamationmark.bubble.fill") {
                            lab.attention()
                        }
                        LabButton(label: "Stop Live Activity", symbol: "stop.fill") {
                            lab.finish()
                        }
                        ProgressView(value: Double(lab.progress), total: 100)
                            .tint(lab.mood.accent)
                        Text("Long-press the Island to expand. The system decides whether an alert expands it automatically.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }

                    LabPanel(heading: "03 · Notification banner", info: "Local notifications · expandable avatar preview · action buttons") {
                        LabButton(label: "Enable Notifications", symbol: "bell.badge") {
                            lab.requestNotifications()
                        }
                        LabButton(label: "Send test banner", symbol: "paperplane.fill") {
                            lab.sendBanner()
                        }
                        Text("Works without internet or APNs. Long-press a banner to preview Bloub artwork.")
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
                        Text("Widgets show a static Bloub snapshot; continuous animation runs inside this app only.")
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
    }
}

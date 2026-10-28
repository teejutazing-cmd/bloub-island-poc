import SwiftUI
import ActivityKit

@MainActor
final class DemoActivityManager: ObservableObject {
    @Published var message = "Ready"
    @Published var progress = 0
    @Published var running = false
    private var activity: Activity<BloubAttributes>?

    init() {
        activity = Activity<BloubAttributes>.activities.first
        if let activity {
            running = true
            progress = activity.content.state.progress
            message = "Active on Dynamic Island"
        }
    }

    func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            message = "Enable Live Activities in iPhone Settings."
            return
        }
        guard !running else { return }
        do {
            let content = ActivityContent(
                state: BloubAttributes.ContentState(phase: "Working", progress: 10),
                staleDate: nil
            )
            activity = try Activity<BloubAttributes>.request(
                attributes: BloubAttributes(agentName: "Bloub"),
                content: content, pushType: nil
            )
            progress = 10
            running = true
            message = "Started. Check Dynamic Island."
        } catch {
            message = "Start failed: \(error.localizedDescription)"
        }
    }

    func advance() {
        guard let activity else { return }
        let next = min(progress + 20, 100)
        Task {
            await activity.update(ActivityContent(
                state: BloubAttributes.ContentState(
                    phase: next == 100 ? "Done" : "Working", progress: next
                ), staleDate: nil
            ))
            progress = next
            message = "Updated to \(next)%"
        }
    }

    func finish() {
        guard let activity else { return }
        Task {
            await activity.end(
                ActivityContent(
                    state: BloubAttributes.ContentState(phase: "Done", progress: 100),
                    staleDate: nil
                ), dismissalPolicy: .immediate
            )
            self.activity = nil
            progress = 0
            running = false
            message = "Ended"
        }
    }
}

struct ControlView: View {
    @StateObject private var manager = DemoActivityManager()
    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(.cyan).frame(width: 92, height: 92)
                HStack(spacing: 12) {
                    Circle().frame(width: 9, height: 9)
                    Circle().frame(width: 9, height: 9)
                }.foregroundStyle(.black).offset(y: -4)
            }
            Text("BLOUB").font(.system(size: 38, weight: .bold, design: .rounded))
            Text("Dynamic Island Proof of Concept").font(.subheadline)
            Text(manager.message).multilineTextAlignment(.center).foregroundStyle(.cyan)
            ProgressView(value: Double(manager.progress), total: 100).tint(.cyan)
            Button("1 · Start Live Activity", action: manager.start)
                .buttonStyle(.borderedProminent).disabled(manager.running)
            Button("2 · Update +20%", action: manager.advance)
                .buttonStyle(.bordered).disabled(!manager.running)
            Button("3 · End Activity", action: manager.finish)
                .buttonStyle(.bordered).disabled(!manager.running)
            Spacer()
            Text("Offline test. No OpenClaw, Craft, Pilot or APNs.")
                .font(.footnote).foregroundStyle(.secondary)
        }.padding(24)
    }
}

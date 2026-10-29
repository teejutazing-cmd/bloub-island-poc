import ActivityKit
import WidgetKit
import SwiftUI

@main
struct BloubWidgetBundle: WidgetBundle {
    var body: some Widget {
        BloubLiveActivityWidget()
        BloubHomeWidget()
        BloubLockWidget()
        if #available(iOS 18.0, *) {
            BloubLaunchControlWidget()
        }
    }
}

private struct IslandStatus: View {
    let mood: BloubMood
    let progress: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: mood.symbol).foregroundStyle(mood.accent)
            Text(mood.title).font(.caption.weight(.medium))
            Spacer(minLength: 5)
            Text("\(progress)%").foregroundStyle(mood.accent)
                .font(.caption.monospacedDigit().weight(.bold))
        }
    }
}

struct BloubLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BloubAttributes.self) { context in
            let mood = BloubMood(rawValue: context.state.mood) ?? .working
            let stage = context.state.islandAlertStage ?? 0
            let tick = context.state.islandAlertTick ?? 0
            HStack(spacing: 14) {
                BloubLiveAvatar(mood: mood, size: 76,
                                pose: context.state.pose, morphFrame: context.state.morphFrame)
                    .scaleEffect(stage == 2 ? 1.13 : 1)
                    .animation(.spring(response: 0.55, dampingFraction: 0.62), value: tick)
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("BLOUB").font(.caption.monospaced().weight(.bold)).tracking(2)
                        Spacer()
                        Text("\(context.state.progress)%")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(mood.accent)
                    }
                    Text(stage == 2 ? "⚠️ ISLAND ALERT" : stage == 3 ? "✅ TASK COMPLETE" : context.state.phase)
                        .font(.headline).foregroundStyle(stage == 2 ? mood.accent : .primary)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.45), value: tick)
                    Text(stage == 2 ? "Bloub needs your attention" : context.state.detail)
                        .font(.caption2).lineLimit(2)
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(context.state.progress), total: 100)
                        .tint(mood.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color(red: 0.05, green: 0.07, blue: 0.11))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let mood = BloubMood(rawValue: context.state.mood) ?? .working
            let style = context.state.animationStyle ?? 0
            let stage = context.state.islandAlertStage ?? 0
            let tick = context.state.islandAlertTick ?? 0
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        BloubLiveAvatar(mood: mood, size: stage == 2 ? 48 : 36,
                                        pose: context.state.pose, morphFrame: context.state.morphFrame)
                            .scaleEffect(stage == 2 ? 1.12 : 1)
                            .animation(.spring(response: 0.48, dampingFraction: 0.5), value: tick)
                        Text(stage == 2 ? "ALERT" : "Bloub")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(stage == 2 ? mood.accent : .primary)
                            .contentTransition(.opacity)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.progress)%")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(mood.accent)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(stage == 2 ? "⚠ BLOUB NEEDS YOUR ATTENTION" :
                         stage == 3 ? "✓ BLOUB FINISHED THE TASK" :
                         context.state.morphFrame >= 0 ? "● BLOUB MORPH · SYSTEM FRAMES" :
                         style > 0 ? "● TRANSITION TEST \(style + 1)/6" :
                         context.state.detail)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(mood == .approval ? .orange : .secondary)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        if stage >= 2 {
                            HStack(spacing: 8) {
                                Image(systemName: stage == 2 ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                                    .foregroundStyle(mood.accent)
                                    .symbolEffect(.bounce, value: tick)
                                Text(stage == 2 ? "EXPANDED ISLAND ALERT" : "TASK COMPLETED")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(mood.accent)
                                    .contentTransition(.opacity)
                            }
                            .padding(.vertical, 3)
                            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: tick)
                        }
                        IslandStatus(mood: mood, progress: context.state.progress)
                        ProgressView(value: Double(context.state.progress), total: 100)
                            .tint(mood.accent)
                        if style > 0 {
                            Text("LIVE TRANSITION STYLE \(style + 1)/6")
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundStyle(mood.accent)
                                .transition(style.isMultiple(of: 2) ? .opacity : .move(edge: .trailing))
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                BloubLiveAvatar(mood: mood, size: 24,
                                pose: context.state.pose, morphFrame: context.state.morphFrame)
                    .scaleEffect(stage == 2 ? 1.12 : 1)
                    .animation(.easeOut(duration: 0.48), value: tick)
            } compactTrailing: {
                Text(stage == 2 ? "!" : style == 5 ? "!" : "\(context.state.progress)%")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(mood.accent)
                    .contentTransition(style.isMultiple(of: 2) ? .numericText() : .opacity)
            } minimal: {
                BloubLiveAvatar(mood: mood, size: 23,
                                pose: context.state.pose, morphFrame: context.state.morphFrame)
            }
            .keylineTint(stage == 2 ? .orange : mood.accent)
        }
    }
}

struct StaticBloubEntry: TimelineEntry {
    let date: Date
    let mood: BloubMood
    let pose: Int
}

struct StaticBloubProvider: TimelineProvider {
    func placeholder(in context: Context) -> StaticBloubEntry {
        StaticBloubEntry(date: Date(), mood: .working, pose: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (StaticBloubEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StaticBloubEntry>) -> Void) {
        // Slow avatar pose rotation. WidgetKit owns refresh scheduling and can defer entries.
        let moods: [BloubMood] = [.working, .recent, .sleeping, .unknown]
        let manualPose = UserDefaults.standard.integer(forKey: "BloubUltimate.widgetPose")
        let now = Date()
        let entries = (0..<4).map { index in
            StaticBloubEntry(date: now.addingTimeInterval(Double(index) * 20 * 60),
                             mood: moods[index], pose: (index + 1 + manualPose) % 5)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

private struct HomeBloubView: View {
    let entry: StaticBloubEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            HStack(spacing: 14) {
                BloubStill(mood: entry.mood, size: 104, frame: entry.pose)
                VStack(alignment: .leading, spacing: 6) {
                    Text("BLOUB").font(.caption.monospaced().weight(.bold)).tracking(2)
                    Text("Avatar Lab").font(.headline)
                    Text("\(entry.mood.title) · scheduled pose")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button(intent: CycleBloubPoseIntent()) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.title3)
                        .foregroundStyle(.cyan)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Next Bloub pose")
            }
            .padding(12)
            .containerBackground(Color(red: 0.035, green: 0.07, blue: 0.11), for: .widget)
        default:
            VStack(spacing: 5) {
                BloubStill(mood: entry.mood, size: 94, frame: entry.pose)
                Text("BLOUB").font(.caption.monospaced().bold()).tracking(1.5)
                Text("OFFLINE LAB").font(.system(size: 9)).foregroundStyle(.secondary)
                Button(intent: CycleBloubPoseIntent()) {
                    Label("NEXT POSE", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 9, weight: .bold))
                }
                .buttonStyle(.plain)
            }
            .containerBackground(Color(red: 0.035, green: 0.07, blue: 0.11), for: .widget)
        }
    }
}

struct BloubHomeWidget: Widget {
    let kind = "BloubHome"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StaticBloubProvider()) { entry in
            HomeBloubView(entry: entry)
                .widgetURL(URL(string: "bloub://lab"))
        }
        .configurationDisplayName("Bloub Avatar")
        .description("Preview Bloub on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct LockBloubView: View {
    let entry: StaticBloubEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            BloubStill(mood: entry.mood, size: 46, frame: entry.pose)
                .containerBackground(.clear, for: .widget)
        case .accessoryRectangular:
            HStack(spacing: 8) {
                BloubStill(mood: entry.mood, size: 37, frame: entry.pose)
                VStack(alignment: .leading, spacing: 2) {
                    Text("BLOUB").font(.caption.bold())
                    Text("Avatar Lab").font(.caption2)
                }
            }
            .containerBackground(.clear, for: .widget)
        default:
            Text("● BLOUB").font(.caption.bold())
                .containerBackground(.clear, for: .widget)
        }
    }
}

struct BloubLockWidget: Widget {
    let kind = "BloubLock"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StaticBloubProvider()) { entry in
            LockBloubView(entry: entry)
                .widgetURL(URL(string: "bloub://lab"))
        }
        .configurationDisplayName("Bloub Lock Screen")
        .description("Bloub avatar in the Lock Screen widget area.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

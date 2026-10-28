import ActivityKit
import WidgetKit
import SwiftUI

@main
struct BloubWidgetBundle: WidgetBundle {
    var body: some Widget {
        BloubLiveActivityWidget()
        BloubHomeWidget()
        BloubLockWidget()
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
            HStack(spacing: 14) {
                BloubStill(mood: mood, size: 76)
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("BLOUB").font(.caption.monospaced().weight(.bold)).tracking(2)
                        Spacer()
                        Text("\(context.state.progress)%")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(mood.accent)
                    }
                    Text(context.state.phase).font(.headline)
                    Text(context.state.detail).font(.caption2).lineLimit(2)
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
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        BloubStill(mood: mood, size: 34)
                        Text("Bloub").font(.headline.weight(.semibold))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.progress)%")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(mood.accent)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        IslandStatus(mood: mood, progress: context.state.progress)
                        ProgressView(value: Double(context.state.progress), total: 100)
                            .tint(mood.accent)
                    }
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                BloubStill(mood: mood, size: 24)
            } compactTrailing: {
                Text("\(context.state.progress)%")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(mood.accent)
            } minimal: {
                BloubStill(mood: mood, size: 23)
            }
            .keylineTint(mood.accent)
        }
    }
}

struct StaticBloubEntry: TimelineEntry {
    let date: Date
}

struct StaticBloubProvider: TimelineProvider {
    func placeholder(in context: Context) -> StaticBloubEntry { StaticBloubEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (StaticBloubEntry) -> Void) {
        completion(StaticBloubEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<StaticBloubEntry>) -> Void) {
        completion(Timeline(entries: [StaticBloubEntry(date: Date())], policy: .never))
    }
}

private struct HomeBloubView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            HStack(spacing: 14) {
                BloubStill(mood: .working, size: 104)
                VStack(alignment: .leading, spacing: 6) {
                    Text("BLOUB").font(.caption.monospaced().weight(.bold)).tracking(2)
                    Text("Avatar Lab").font(.headline)
                    Text("Tap to explore moods")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .containerBackground(Color(red: 0.035, green: 0.07, blue: 0.11), for: .widget)
        default:
            VStack(spacing: 5) {
                BloubStill(mood: .working, size: 94)
                Text("BLOUB").font(.caption.monospaced().bold()).tracking(1.5)
                Text("OFFLINE LAB").font(.system(size: 9)).foregroundStyle(.secondary)
            }
            .containerBackground(Color(red: 0.035, green: 0.07, blue: 0.11), for: .widget)
        }
    }
}

struct BloubHomeWidget: Widget {
    let kind = "BloubHome"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StaticBloubProvider()) { _ in
            HomeBloubView()
                .widgetURL(URL(string: "bloub://lab"))
        }
        .configurationDisplayName("Bloub Avatar")
        .description("Preview Bloub on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct LockBloubView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            BloubStill(mood: .working, size: 46)
                .containerBackground(.clear, for: .widget)
        case .accessoryRectangular:
            HStack(spacing: 8) {
                BloubStill(mood: .working, size: 37)
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
        StaticConfiguration(kind: kind, provider: StaticBloubProvider()) { _ in
            LockBloubView()
                .widgetURL(URL(string: "bloub://lab"))
        }
        .configurationDisplayName("Bloub Lock Screen")
        .description("Bloub avatar in the Lock Screen widget area.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

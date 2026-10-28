import ActivityKit
import WidgetKit
import SwiftUI

@main
struct BloubWidgetBundle: WidgetBundle {
    var body: some Widget { BloubLiveActivityWidget() }
}

private struct BloubFace: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Circle().fill(.cyan)
            HStack(spacing: size * 0.13) {
                Circle().fill(.black).frame(width: size * 0.1, height: size * 0.1)
                Circle().fill(.black).frame(width: size * 0.1, height: size * 0.1)
            }
        }.frame(width: size, height: size)
    }
}

struct BloubLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BloubAttributes.self) { context in
            HStack(spacing: 12) {
                BloubFace(size: 42)
                VStack(alignment: .leading) {
                    Text(context.attributes.agentName).font(.headline)
                    Text("\(context.state.phase) · \(context.state.progress)%")
                    ProgressView(value: Double(context.state.progress), total: 100)
                        .tint(.cyan)
                }
            }.padding()
             .activityBackgroundTint(.black)
             .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        BloubFace(size: 24)
                        Text(context.attributes.agentName).font(.headline)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.progress)%").foregroundStyle(.cyan)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack {
                        Text("Agent · \(context.state.phase)")
                        ProgressView(value: Double(context.state.progress), total: 100)
                            .tint(.cyan)
                    }.padding(.top, 5)
                }
            } compactLeading: {
                BloubFace(size: 23)
            } compactTrailing: {
                Text("\(context.state.progress)%").foregroundStyle(.cyan)
            } minimal: {
                BloubFace(size: 23)
            }
            .keylineTint(.cyan)
        }
    }
}

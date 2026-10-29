import WidgetKit
import SwiftUI
import AppIntents

// No custom animation is drawn in Control Center; the system presents a
// standard SF Symbol and opens the app via an OpenIntent.
@available(iOS 18.0, *)
struct BloubLaunchControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.bloub.island.poc.control.open") {
            ControlWidgetButton(action: OpenBloubUltimateIntent()) {
                Label("Bloub Lab", systemImage: "sparkles.rectangle.stack")
            }
        }
        .displayName("Open Bloub Lab")
        .description("Open the native Bloub animation experiments.")
    }
}

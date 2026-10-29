import AppIntents
import WidgetKit
import Foundation

// Interactive Home Widget button, no server or App Group required.
// The value is stored within this widget extension's UserDefaults container.
struct CycleBloubPoseIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Bloub pose"
    static var description = IntentDescription("Cycle the local Bloub avatar pose on its Home Screen widget.")

    func perform() async throws -> some IntentResult {
        let key = "BloubUltimate.widgetPose"
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set((current + 1) % 5, forKey: key)
        WidgetCenter.shared.reloadTimelines(ofKind: "BloubHome")
        return .result()
    }
}

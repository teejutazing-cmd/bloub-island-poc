import SwiftUI

@main
struct BloubIslandApp: App {
    init() {
        LabNotificationDelegate.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ControlView().preferredColorScheme(.dark)
        }
    }
}

import AppIntents

// Control Center, Lock Screen controls and Action Button can launch Bloub.
// Both the app and the Widget extension compile this intent via Shared/.
@available(iOS 18.0, *)
enum BloubDestination: String, AppEnum {
    case ultimate

    static var typeDisplayRepresentation = TypeDisplayRepresentation("Bloub screen")
    static var caseDisplayRepresentations: [BloubDestination: DisplayRepresentation] = [
        .ultimate: DisplayRepresentation("Ultimate Animation Lab")
    ]
}

@available(iOS 18.0, *)
struct OpenBloubUltimateIntent: OpenIntent {
    static var title: LocalizedStringResource = "Open Bloub Ultimate Lab"

    @Parameter(title: "Screen")
    var target: BloubDestination

    init() { target = .ultimate }
}

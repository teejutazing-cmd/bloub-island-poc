import ActivityKit
struct BloubAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: String
        var progress: Int
    }
    var agentName: String
}

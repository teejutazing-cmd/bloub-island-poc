import ActivityKit

struct BloubAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: String
        var progress: Int
        var mood: String
        var detail: String
        var pose: Int
        // -1 = normal avatar; 0...23 = one original source morph frame.
        var morphFrame: Int
        // Discrete animation transition lab; nil preserves previous Live Activity state.
        var animationStyle: Int? = nil
    }

    var agentName: String
}

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
        // Live Activity alert experiment (0 idle, 1 armed, 2 urgent, 3 resolved).
        // Optional to decode Live Activities left running by older Bloub versions.
        var islandAlertStage: Int? = nil
        var islandAlertTick: Int? = nil
    }

    var agentName: String
}

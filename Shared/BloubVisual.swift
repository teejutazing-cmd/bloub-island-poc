import SwiftUI

enum BloubMood: String, CaseIterable, Identifiable {
    case working, approval, recent, sleeping, error, unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .working: return "Working"
        case .approval: return "Approval"
        case .recent: return "Completed"
        case .sleeping: return "Sleeping"
        case .error: return "Error"
        case .unknown: return "Idle"
        }
    }

    var accent: Color {
        switch self {
        case .working: return .cyan
        case .approval: return .orange
        case .recent: return .green
        case .sleeping: return .purple
        case .error: return .red
        case .unknown: return .mint
        }
    }

    var symbol: String {
        switch self {
        case .working: return "gearshape.2.fill"
        case .approval: return "exclamationmark.circle.fill"
        case .recent: return "checkmark.circle.fill"
        case .sleeping: return "moon.stars.fill"
        case .error: return "xmark.octagon.fill"
        case .unknown: return "circle.dotted.circle.fill"
        }
    }
}

// The original Bloub working sheet contains the exact circle-to-triangle morph.
// These 24 assets are source frames [0, 3, ... 69], not generated geometric substitutes.
// System-managed Live Activity updates may merge frames. This view does not run a timer.
struct BloubMorphFrame: View {
    let frame: Int
    let size: CGFloat

    private var imageName: String {
        let index = max(0, min(frame, 23))
        return index < 10 ? "bloub-morph-0\(index)" : "bloub-morph-\(index)"
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("Original Bloub morph frame \(frame + 1) of 24")
    }
}

struct BloubLiveAvatar: View {
    let mood: BloubMood
    let size: CGFloat
    let pose: Int
    let morphFrame: Int

    var body: some View {
        Group {
            if morphFrame >= 0 {
                BloubMorphFrame(frame: morphFrame, size: size)
                    .id("morph-\(morphFrame)")
                    .transition(.identity)
            } else {
                BloubStill(mood: mood, size: size, frame: pose)
                    .id("pose-\(mood.rawValue)-\(pose)")
                    .transition(.opacity)
            }
        }
    }
}

// Discrete sprite poses can animate between Live Activity STATE UPDATES.
// WidgetKit cannot freely run TimelineView or an arbitrary 144-frame loop here.
struct BloubStill: View {
    let mood: BloubMood
    let size: CGFloat
    var frame: Int = 0

    var body: some View {
        Image(frame == 0 ? "bloub-still-\(mood.rawValue)" :
               "bloub-pose-\(mood.rawValue)-\(max(0, min(frame, 4)))")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("Bloub \(mood.title) pose \(frame)")
    }
}

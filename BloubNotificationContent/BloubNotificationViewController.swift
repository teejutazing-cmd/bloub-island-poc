import UIKit
import UserNotifications
import UserNotificationsUI

// This screen is presented ONLY when the user EXPANDS a delivered notification.
// The system-drawn collapsed banner cannot run our animation.
final class BloubNotificationViewController: UIViewController, UNNotificationContentExtension {
    private let sprite = UIImageView()
    private let heading = UILabel()
    private let subheading = UILabel()
    private let status = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.035, green: 0.055, blue: 0.09, alpha: 1)

        heading.text = "BLOUB"
        heading.font = .monospacedSystemFont(ofSize: 15, weight: .bold)
        heading.textColor = .systemTeal
        heading.textAlignment = .center

        sprite.contentMode = .scaleAspectFit
        sprite.layer.magnificationFilter = .nearest
        sprite.setContentHuggingPriority(.defaultLow, for: .vertical)

        subheading.textColor = .white
        subheading.font = .systemFont(ofSize: 18, weight: .semibold)
        subheading.numberOfLines = 2
        subheading.textAlignment = .center

        status.text = "ANIMATED NOTIFICATION · 12 FPS"
        status.font = .monospacedSystemFont(ofSize: 9, weight: .medium)
        status.textColor = .lightGray
        status.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [heading, sprite, subheading, status])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            sprite.heightAnchor.constraint(equalToConstant: 112)
        ])
        preferredContentSize = CGSize(width: 330, height: 235)
    }

    func didReceive(_ notification: UNNotification) {
        let rawMood = notification.request.content.userInfo["bloubMood"] as? String ?? "working"
        let allowed = ["working", "approval", "recent", "sleeping", "error", "unknown"]
        let mood = allowed.contains(rawMood) ? rawMood : "working"
        subheading.text = notification.request.content.title
        let color: UIColor = mood == "error" ? .systemRed :
            mood == "approval" ? .systemOrange : .systemTeal
        heading.textColor = color

        sprite.stopAnimating()
        sprite.animationImages = nil
        sprite.layer.removeAllAnimations()
        let fx = notification.request.content.userInfo["bloubFX"] as? String ?? "default"
        let isMorph = notification.request.content.userInfo["bloubMorph"] as? Bool ?? false
        status.text = isMorph ? "CIRCLE → TRIANGLE · 24 REAL FRAMES / 2s" : "ORIGINAL SPRITE · 144 FRAMES / 12s"
        guard let sourceURL = Bundle.main.url(forResource: "bloub-04-\(mood)", withExtension: "png"),
              let sheet = UIImage(contentsOfFile: sourceURL.path)?.cgImage else {
            subheading.text = "Bloub \(mood.capitalized)"
            return
        }

        // Original sprite: 144 frames, each 64x64, one horizontal 9216x64 sheet.
        // Animate only inside the expanded notification view; not in Dynamic Island.
        var frames: [UIImage] = []
        let sourceIndices = isMorph ? (0..<24).map { $0 * 3 } : Array(0..<144)
        frames.reserveCapacity(sourceIndices.count)
        for index in sourceIndices {
            let rect = CGRect(x: index * 64, y: 0, width: 64, height: 64)
            if let slice = sheet.cropping(to: rect) {
                frames.append(UIImage(cgImage: slice, scale: 1, orientation: .up))
            }
        }
        guard !frames.isEmpty else { return }
        sprite.image = isMorph ? frames[frames.count - 1] : frames[0]
        sprite.animationImages = frames
        sprite.animationDuration = isMorph ? 2 : 12
        sprite.animationRepeatCount = isMorph ? 1 : 0
        sprite.startAnimating()
        // This is real UIKit/Core Animation in the expanded notification only.
        // The standard iOS notification banner remains system-owned.
        applyFX(fx)
    }

    private func applyFX(_ effect: String) {
        let animation = CABasicAnimation()
        animation.duration = 0.65
        animation.autoreverses = true
        animation.repeatCount = 5
        sprite.layer.shadowColor = UIColor.systemRed.cgColor
        sprite.layer.shadowRadius = 20
        sprite.layer.shadowOffset = .zero

        switch effect {
        case "glow":
            sprite.layer.shadowOpacity = 1
            animation.keyPath = "shadowRadius"
            animation.fromValue = 4
            animation.toValue = 48
        case "spin":
            animation.keyPath = "transform.rotation.z"
            animation.duration = 2
            animation.autoreverses = false
            animation.fromValue = 0
            animation.toValue = Double.pi * 2
            animation.repeatCount = 2
        case "pulse":
            animation.keyPath = "transform.scale"
            animation.fromValue = 0.75
            animation.toValue = 1.33
        case "shake":
            animation.keyPath = "transform.translation.x"
            animation.fromValue = -18
            animation.toValue = 18
            animation.duration = 0.11
            animation.repeatCount = 18
        case "ripple":
            animation.keyPath = "transform.scale"
            animation.fromValue = 0.85
            animation.toValue = 1.4
            sprite.layer.shadowOpacity = 1
            sprite.layer.shadowRadius = 35
        case "glitch":
            let glitch = CAKeyframeAnimation(keyPath: "transform.translation.x")
            glitch.values = [0, 18, -24, 9, -12, 0]
            glitch.keyTimes = [0, 0.2, 0.38, 0.61, 0.84, 1] as [NSNumber]
            glitch.duration = 0.3
            glitch.repeatCount = 10
            sprite.layer.add(glitch, forKey: "bloub-glitch")
            status.text = "GLITCH · CORE ANIMATION"
            return
        default:
            return
        }
        sprite.layer.add(animation, forKey: "bloub-\(effect)")
        status.text = "BLOUB FX · \(effect.uppercased()) · EXPANDED ONLY"
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sprite.stopAnimating()
        sprite.animationImages = nil
    }
}

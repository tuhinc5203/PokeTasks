import AppKit

enum SoundEffects {
    private static let enabledDefaultsKey = "com.poketasks.soundEffectsEnabled"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledDefaultsKey)
    }

    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: enabledDefaultsKey)
    }

    static func play(for reaction: PetReaction) {
        guard isEnabled else { return }
        switch reaction {
        case .levelUp:
            NSSound(named: "Tink")?.play()
        case .hatch, .evolve, .shiny:
            NSSound(named: "Glass")?.play()
        case .hearts:
            NSSound(named: "Purr")?.play()
        }
    }
}

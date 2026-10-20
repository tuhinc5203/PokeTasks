import Foundation

final class PetCollectionStore {
    private let defaultsKey = "com.poketasks.petCollection"
    private let legacyDefaultsKey = "com.snorlaxpet.petCollection"
    private let defaults: UserDefaults
    private let legacyDefaults: UserDefaults?

    init(defaults: UserDefaults = .standard, legacyDefaults: UserDefaults? = UserDefaults(suiteName: "com.snorlaxpet.app")) {
        self.defaults = defaults
        self.legacyDefaults = legacyDefaults
    }

    func load() -> PetCollectionState? {
        if let data = defaults.data(forKey: defaultsKey),
           let state = try? JSONDecoder().decode(PetCollectionState.self, from: data) {
            return state
        }
        if let legacyData = legacyDefaults?.data(forKey: legacyDefaultsKey),
           let state = try? JSONDecoder().decode(PetCollectionState.self, from: legacyData) {
            save(state)
            return state
        }
        return nil
    }

    func save(_ state: PetCollectionState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: defaultsKey)
    }
}

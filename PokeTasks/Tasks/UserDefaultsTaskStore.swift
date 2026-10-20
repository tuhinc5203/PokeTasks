import Foundation

final class UserDefaultsTaskStore: TaskStore {
    private let defaultsKey = "com.poketasks.tasks"
    private let legacyDefaultsKey = "com.snorlaxpet.tasks"
    private let lastPruneAtKey = "com.poketasks.lastPruneAt"
    private let defaults: UserDefaults
    private let legacyDefaults: UserDefaults?

    init(defaults: UserDefaults = .standard, legacyDefaults: UserDefaults? = UserDefaults(suiteName: "com.snorlaxpet.app")) {
        self.defaults = defaults
        self.legacyDefaults = legacyDefaults
    }

    func loadTasks() -> [PetTask] {
        if let data = defaults.data(forKey: defaultsKey),
           let tasks = try? JSONDecoder().decode([PetTask].self, from: data) {
            return tasks
        }
        if let legacyData = legacyDefaults?.data(forKey: legacyDefaultsKey),
           let tasks = try? JSONDecoder().decode([PetTask].self, from: legacyData) {
            save(tasks: tasks)
            return tasks
        }
        return []
    }

    func save(tasks: [PetTask]) {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        defaults.set(data, forKey: defaultsKey)
    }

    func loadLastPruneAt() -> Date? {
        defaults.object(forKey: lastPruneAtKey) as? Date
    }

    func saveLastPruneAt(_ date: Date) {
        defaults.set(date, forKey: lastPruneAtKey)
    }
}

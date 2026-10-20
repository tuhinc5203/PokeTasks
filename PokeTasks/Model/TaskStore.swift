import Foundation

protocol TaskStore {
    func loadTasks() -> [PetTask]
    func save(tasks: [PetTask])
    func loadLastPruneAt() -> Date?
    func saveLastPruneAt(_ date: Date)
}

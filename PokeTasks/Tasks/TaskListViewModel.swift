import Foundation
import Combine
import SwiftUI

final class TaskListViewModel: ObservableObject {
    @Published private(set) var tasks: [PetTask] = []

    private let store: TaskStore
    private let petCollectionViewModel: PetCollectionViewModel
    private static let globalClearInterval: TimeInterval = 6 * 60 * 60

    init(store: TaskStore, petCollectionViewModel: PetCollectionViewModel) {
        self.store = store
        self.petCollectionViewModel = petCollectionViewModel
        self.tasks = store.loadTasks()
        pruneExpiredTasks()
    }

    func addTask(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let task = PetTask(id: UUID(), title: trimmed, isCompleted: false, createdAt: Date(), completedAt: nil)
        tasks.insert(task, at: 0)
        persist()
        TodoArchiveWriter.recordTaskAdded(task)
    }

    func renameTask(_ task: PetTask, to newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].title = trimmed
        persist()
        TodoArchiveWriter.recordTaskRenamed(tasks[index])
    }

    func toggleCompletion(_ task: PetTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
        tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
        persist()
        TodoArchiveWriter.recordTaskToggled(tasks[index])
        if tasks[index].isCompleted {
            petCollectionViewModel.registerCompletion()
        }
    }

    func deleteTask(_ task: PetTask) {
        tasks.removeAll { $0.id == task.id }
        persist()
    }

    func addSubtask(to task: PetTask, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].subtasks.append(Subtask(id: UUID(), title: trimmed, isCompleted: false))
        persist()
    }

    func renameSubtask(_ subtask: Subtask, in task: PetTask, to newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let taskIndex = tasks.firstIndex(where: { $0.id == task.id }),
              let subtaskIndex = tasks[taskIndex].subtasks.firstIndex(where: { $0.id == subtask.id }) else { return }
        tasks[taskIndex].subtasks[subtaskIndex].title = trimmed
        persist()
    }

    func toggleSubtaskCompletion(_ subtask: Subtask, in task: PetTask) {
        guard let taskIndex = tasks.firstIndex(where: { $0.id == task.id }),
              let subtaskIndex = tasks[taskIndex].subtasks.firstIndex(where: { $0.id == subtask.id }) else { return }
        tasks[taskIndex].subtasks[subtaskIndex].isCompleted.toggle()
        persist()
        if tasks[taskIndex].subtasks[subtaskIndex].isCompleted {
            petCollectionViewModel.registerCompletion()
        }
    }

    func deleteSubtask(_ subtask: Subtask, from task: PetTask) {
        guard let taskIndex = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[taskIndex].subtasks.removeAll { $0.id == subtask.id }
        persist()
    }

    func moveTask(fromOffsets source: IndexSet, toOffset destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    func pruneExpiredTasks() {
        guard let lastPruneAt = store.loadLastPruneAt() else {
            // First time this has ever run -- just establish the baseline. Nothing to clear yet.
            store.saveLastPruneAt(Date())
            return
        }
        guard Date().timeIntervalSince(lastPruneAt) >= Self.globalClearInterval else { return }
        removeCompleted()
        persist()
        store.saveLastPruneAt(Date())
    }

    func clearCompletedTasks() {
        removeCompleted()
        persist()
    }

    /// Drops completed tasks, plus any completed subtasks still sitting under open tasks.
    /// (A completed task's subtasks go with it.)
    private func removeCompleted() {
        tasks.removeAll { $0.isCompleted }
        for index in tasks.indices {
            tasks[index].subtasks.removeAll { $0.isCompleted }
        }
    }

    private func persist() {
        store.save(tasks: tasks)
    }
}

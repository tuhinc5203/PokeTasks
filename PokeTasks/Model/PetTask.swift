import Foundation

struct Subtask: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
}

struct PetTask: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var subtasks: [Subtask]

    init(id: UUID, title: String, isCompleted: Bool, createdAt: Date, completedAt: Date?, subtasks: [Subtask] = []) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.subtasks = subtasks
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, isCompleted, createdAt, completedAt, subtasks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        // Older saved tasks predate subtasks -- default to none rather than failing to decode.
        subtasks = try container.decodeIfPresent([Subtask].self, forKey: .subtasks) ?? []
    }
}

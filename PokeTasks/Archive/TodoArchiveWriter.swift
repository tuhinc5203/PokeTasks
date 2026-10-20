import Foundation

enum TodoArchiveWriter {
    private static let archiveURL: URL = {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Archive/
            .deletingLastPathComponent() // PokeTasks/
            .deletingLastPathComponent() // poketasks/
            .appendingPathComponent("TodoArchive.md")
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func recordTaskAdded(_ task: PetTask) {
        appendOrUpdate(task)
    }

    static func recordTaskToggled(_ task: PetTask) {
        appendOrUpdate(task)
    }

    static func recordTaskRenamed(_ task: PetTask) {
        appendOrUpdate(task)
    }

    private static func appendOrUpdate(_ task: PetTask) {
        let header = "## \(dateFormatter.string(from: task.createdAt))"
        let marker = "<!-- \(task.id.uuidString) -->"
        let newLine = "- [\(task.isCompleted ? "x" : " ")] \(task.title) \(marker)"

        var lines = (try? String(contentsOf: archiveURL, encoding: .utf8))?
            .components(separatedBy: "\n") ?? []

        if let lineIndex = lines.firstIndex(where: { $0.hasSuffix(marker) }) {
            lines[lineIndex] = newLine
        } else if let headerIndex = lines.firstIndex(of: header) {
            var insertAt = headerIndex + 1
            while insertAt < lines.count && !lines[insertAt].hasPrefix("## ") {
                insertAt += 1
            }
            lines.insert(newLine, at: insertAt)
        } else {
            if !lines.isEmpty && lines.last != "" {
                lines.append("")
            }
            lines.append(header)
            lines.append(newLine)
        }

        let output = lines.joined(separator: "\n")
        try? output.write(to: archiveURL, atomically: true, encoding: .utf8)
    }
}

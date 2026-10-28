import SwiftUI

struct TaskRowView: View {
    let task: PetTask
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onRename: (String) -> Void
    let onAddSubtask: (String) -> Void
    let onToggleSubtask: (Subtask) -> Void
    let onDeleteSubtask: (Subtask) -> Void
    let onRenameSubtask: (Subtask, String) -> Void

    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var isAddingSubtask = false
    @State private var newSubtaskText = ""
    @State private var isExpanded = true
    @FocusState private var isNewSubtaskFieldFocused: Bool
    @FocusState private var isTitleFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.square" : "square")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                if isEditing {
                    TextField("", text: $editedTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($isTitleFieldFocused)
                        .onSubmit(commitRename)
                        .onExitCommand { isEditing = false }
                } else {
                    Text(task.title)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .font(.system(size: 13))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if !task.subtasks.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isExpanded.toggle()
                        }
                        if !isExpanded { cancelNewSubtask() }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    editedTitle = task.title
                    isEditing = true
                    isTitleFieldFocused = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button {
                    isExpanded = true
                    isAddingSubtask = true
                    isNewSubtaskFieldFocused = true
                } label: {
                    Label("Add Subtask", systemImage: "plus")
                }
            }

            if isExpanded && (!task.subtasks.isEmpty || isAddingSubtask) {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(task.subtasks) { subtask in
                        SubtaskRowView(
                            subtask: subtask,
                            onToggle: { onToggleSubtask(subtask) },
                            onDelete: { onDeleteSubtask(subtask) },
                            onRename: { onRenameSubtask(subtask, $0) }
                        )
                    }

                    if isAddingSubtask {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.tertiary)

                            TextField("New subtask…", text: $newSubtaskText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11))
                                .focused($isNewSubtaskFieldFocused)
                                .onSubmit(commitNewSubtask)
                                .onExitCommand(perform: cancelNewSubtask)
                                .onAppear { isNewSubtaskFieldFocused = true }
                                .onChange(of: isNewSubtaskFieldFocused) { _, isFocused in
                                    if !isFocused && newSubtaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        cancelNewSubtask()
                                    }
                                }

                            Spacer(minLength: 0)

                            Button(action: cancelNewSubtask) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.leading, 22)
            }
        }
    }

    private func commitRename() {
        onRename(editedTitle)
        isEditing = false
    }

    private func commitNewSubtask() {
        onAddSubtask(newSubtaskText)
        newSubtaskText = ""
        isAddingSubtask = false
    }

    private func cancelNewSubtask() {
        newSubtaskText = ""
        isAddingSubtask = false
    }
}

struct SubtaskRowView: View {
    let subtask: Subtask
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onRename: (String) -> Void

    @State private var isEditing = false
    @State private var editedTitle = ""

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onToggle) {
                Image(systemName: subtask.isCompleted ? "checkmark.square" : "square")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("", text: $editedTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .onSubmit(commitRename)
                    .onExitCommand { isEditing = false }
            } else {
                Text(subtask.title)
                    .strikethrough(subtask.isCompleted)
                    .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .onTapGesture(count: 2) {
                        editedTitle = subtask.title
                        isEditing = true
                    }
            }

            Spacer(minLength: 0)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
    }

    private func commitRename() {
        onRename(editedTitle)
        isEditing = false
    }
}

struct NewTaskRowView: View {
    @Binding var text: String
    let onCommit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "square")
                .foregroundStyle(.tertiary)

            TextField("Add a task…", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onSubmit(onCommit)
        }
    }
}

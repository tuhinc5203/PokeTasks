import SwiftUI

private enum CollectionCardModel: Identifiable {
    case unlocked(line: PokemonLine, progress: PetProgress, displayName: String, isActive: Bool, isJustRevealed: Bool)
    case locked(line: PokemonLine)

    var id: String {
        switch self {
        case .unlocked(let line, _, _, _, _): return line.id
        case .locked(let line): return line.id
        }
    }
}

struct CollectionPanelView: View {
    @ObservedObject var taskListViewModel: TaskListViewModel
    @ObservedObject var petCollectionViewModel: PetCollectionViewModel
    @State private var justRevealedID: String?
    @State private var showingResetCollectionConfirmation = false
    @State private var isEditingLabel = false
    @State private var editedLabel = ""
    @AppStorage("com.poketasks.pcBoxLabel") private var boxLabel = "PC Box"

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var cardModels: [CollectionCardModel] {
        var models: [CollectionCardModel] = petCollectionViewModel.knownLines.map { line in
            .unlocked(
                line: line,
                progress: petCollectionViewModel.progress(for: line.id),
                displayName: petCollectionViewModel.starredDisplayName(for: line.id),
                isActive: line.id == petCollectionViewModel.state.activeLineID,
                isJustRevealed: line.id == justRevealedID
            )
        }
        if petCollectionViewModel.hasPendingLegendaryPick {
            models += petCollectionViewModel.lockedBirdLines.map { .locked(line: $0) }
        }
        return models
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if isEditingLabel {
                    TextField("", text: $editedLabel)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                        .onSubmit(commitLabelRename)
                        .onExitCommand { isEditingLabel = false }
                } else {
                    Text(boxLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .onTapGesture(count: 2) {
                            editedLabel = boxLabel
                            isEditingLabel = true
                        }
                }

                Spacer()

                Button {
                    showingResetCollectionConfirmation = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .confirmationDialog(
                    "Every legendary will be removed and every starter will return to an egg. This can't be undone.",
                    isPresented: $showingResetCollectionConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Reset Collection", role: .destructive) {
                        petCollectionViewModel.resetEntireCollection()
                        taskListViewModel.addTask(title: "Choose your Starter!")
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    // Single ForEach over every card, unlocked and locked alike: an id must
                    // never appear in two separate ForEach loops across the unlock transition,
                    // since SwiftUI can't reconcile the same identity switching view types
                    // across sibling loops — it did, and got stuck showing the stale locked card.
                    ForEach(cardModels) { model in
                        switch model {
                        case .unlocked(let line, let progress, let displayName, let isActive, let isJustRevealed):
                            PetCollectionCard(
                                line: line,
                                displayName: displayName,
                                progress: progress,
                                isActive: isActive,
                                isJustRevealed: isJustRevealed
                            ) {
                                petCollectionViewModel.setActive(line.id)
                            }
                        case .locked(let line):
                            LockedBirdCard(line: line) {
                                petCollectionViewModel.choosePendingLegendaryBird(line.id)
                            }
                        }
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .padding(16)
        .frame(width: 260)
        .onChange(of: petCollectionViewModel.unlockRevealTick) { _ in
            guard let revealedID = petCollectionViewModel.lastRevealedLineID else { return }
            justRevealedID = revealedID
            Task {
                try? await Task.sleep(for: .seconds(0.9))
                if justRevealedID == revealedID {
                    justRevealedID = nil
                }
            }
        }
    }

    private func commitLabelRename() {
        let trimmed = editedLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        boxLabel = trimmed.isEmpty ? "PC Box" : trimmed
        isEditingLabel = false
    }
}

private struct PetCollectionCard: View {
    let line: PokemonLine
    let displayName: String
    let progress: PetProgress
    let isActive: Bool
    let isJustRevealed: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Image(nsImage: SpriteImageLoader.shared.loadSprite(
                    named: PetCollectionViewModel.spriteResourceName(for: line, progress: progress),
                    in: .gen1
                ))
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .scaleEffect(isJustRevealed ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.45), value: isJustRevealed)

                if isJustRevealed {
                    ForEach(0..<6, id: \.self) { index in
                        Image(systemName: "sparkle")
                            .font(.system(size: 9))
                            .foregroundStyle(.cyan)
                            .offset(sparkleOffset(index))
                            .allowsHitTesting(false)
                    }
                }
            }
            .frame(width: 56, height: 56)

            Text(displayName)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)

            Text("Lv. \(progress.level)")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

            FriendshipMeterView(level: progress.friendshipLevel, size: 11)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isActive ? Color.accentColor : .clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private func sparkleOffset(_ index: Int) -> CGSize {
        let angle = Double(index) / 6.0 * 2 * .pi
        let radius: CGFloat = 34
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }
}

private struct LockedBirdCard: View {
    let line: PokemonLine
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
                .frame(width: 56, height: 56)

            Text(line.displayName)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)

            Text("Tap to unlock")
                .font(.system(size: 9))
                .foregroundStyle(.yellow)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .foregroundStyle(Color.yellow.opacity(0.6))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

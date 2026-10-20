import SwiftUI

struct PetPopoverView: View {
    @ObservedObject var viewModel: TaskListViewModel
    @ObservedObject var petCollectionViewModel: PetCollectionViewModel

    @State private var newTaskText: String = ""
    @State private var isLevelingUp = false
    @State private var isSquishing = false
    @State private var wiggleAngle: Double = 0
    @State private var showingResetConfirmation = false
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var isShowingHearts = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        if isEditingName {
                            TextField("", text: $editedName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, weight: .medium))
                                .onSubmit(commitRename)
                                .onExitCommand { isEditingName = false }
                        } else {
                            Text(petCollectionViewModel.activeStarredDisplayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .onTapGesture(count: 2) {
                                    editedName = petCollectionViewModel.activeDisplayName
                                    isEditingName = true
                                }
                        }

                        Text("· Lv. \(petCollectionViewModel.activeProgress.level)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)

                        FriendshipMeterView(level: petCollectionViewModel.activeProgress.friendshipLevel, size: 13)
                    }

                    if petCollectionViewModel.hasPendingLegendaryPick {
                        Text("⭐ Swipe to pick a legendary")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.yellow)
                    }
                }

                Spacer()

                Button(action: viewModel.clearCompletedTasks) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)

                Button {
                    showingResetConfirmation = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .confirmationDialog(
                    "\(petCollectionViewModel.activeStarredDisplayName)'s level, shiny status, and lifetime count will be permanently cleared. This can't be undone.",
                    isPresented: $showingResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Reset", role: .destructive) {
                        petCollectionViewModel.resetActivePet()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }

            ZStack {
                Image(nsImage: SpriteImageLoader.shared.loadSprite(
                    named: PetCollectionViewModel.spriteResourceName(
                        for: petCollectionViewModel.activeLine,
                        progress: petCollectionViewModel.activeProgress
                    ),
                    in: .gen1
                ))
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 96, height: 96)
                    .scaleEffect(isLevelingUp ? 1.15 : 1.0)
                    .scaleEffect(x: isSquishing ? 1.18 : 1.0, y: isSquishing ? 0.82 : 1.0)
                    .rotationEffect(.degrees(wiggleAngle))
                    .onTapGesture {
                        triggerSquish()
                    }

                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                        .offset(sparkleOffset(index))
                        .opacity(isLevelingUp ? 1 : 0)
                        .scaleEffect(isLevelingUp ? 1 : 0.3)
                        .allowsHitTesting(false)
                }

                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.pink)
                        .offset(sparkleOffset(index))
                        .opacity(isShowingHearts ? 1 : 0)
                        .scaleEffect(isShowingHearts ? 1 : 0.3)
                        .allowsHitTesting(false)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.45), value: isLevelingUp)
            .animation(.spring(response: 0.3, dampingFraction: 0.45), value: isShowingHearts)
            .animation(.spring(response: 0.25, dampingFraction: 0.4), value: isSquishing)
            .onChange(of: petCollectionViewModel.reactionTick) { _ in
                playReactions(petCollectionViewModel.pendingReactions)
            }

            VStack(alignment: .leading, spacing: 8) {
                List {
                    ForEach(viewModel.tasks) { task in
                        TaskRowView(task: task) {
                            viewModel.toggleCompletion(task)
                        } onDelete: {
                            viewModel.deleteTask(task)
                        } onRename: { newTitle in
                            viewModel.renameTask(task, to: newTitle)
                        } onAddSubtask: { title in
                            viewModel.addSubtask(to: task, title: title)
                        } onToggleSubtask: { subtask in
                            viewModel.toggleSubtaskCompletion(subtask, in: task)
                        } onDeleteSubtask: { subtask in
                            viewModel.deleteSubtask(subtask, from: task)
                        } onRenameSubtask: { subtask, newTitle in
                            viewModel.renameSubtask(subtask, in: task, to: newTitle)
                        }
                        .listRowInsets(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onMove { source, destination in
                        viewModel.moveTask(fromOffsets: source, toOffset: destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: 180)

                NewTaskRowView(text: $newTaskText) {
                    viewModel.addTask(title: newTaskText)
                    newTaskText = ""
                }
            }
        }
        .padding(16)
        .frame(width: 260)
        .confirmationDialog(
            "Claim Shiny?",
            isPresented: Binding(
                get: { petCollectionViewModel.pendingShinyClaim },
                set: { isPresented in
                    if !isPresented {
                        petCollectionViewModel.declineShinyClaim()
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Claim Shiny") {
                petCollectionViewModel.claimShiny()
            }
            Button("Not Yet", role: .cancel) {
                petCollectionViewModel.declineShinyClaim()
            }
        } message: {
            Text("\(petCollectionViewModel.activeDisplayName) will become permanently shiny and restart at level 1 as \(petCollectionViewModel.activeLine.displayName).")
        }
        .confirmationDialog(
            "Claim \(petCollectionViewModel.pendingAutoUnlockDisplayName ?? "")?",
            isPresented: Binding(
                get: { petCollectionViewModel.pendingAutoUnlockID != nil },
                set: { isPresented in
                    if !isPresented {
                        petCollectionViewModel.declineAutoUnlockClaim()
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Claim \(petCollectionViewModel.pendingAutoUnlockDisplayName ?? "")") {
                petCollectionViewModel.claimAutoUnlock()
            }
            Button("Not Yet", role: .cancel) {
                petCollectionViewModel.declineAutoUnlockClaim()
            }
        }
    }

    private func sparkleOffset(_ index: Int) -> CGSize {
        let angle = Double(index) / 6.0 * 2 * .pi
        let radius: CGFloat = 55
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }

    private func playReactions(_ reactions: [PetReaction]) {
        Task {
            for reaction in reactions {
                SoundEffects.play(for: reaction)
                switch reaction {
                case .levelUp:
                    await performWiggle()
                case .hatch, .evolve, .shiny:
                    triggerSparkle()
                    try? await Task.sleep(for: .seconds(0.6))
                case .hearts:
                    triggerHearts()
                    try? await Task.sleep(for: .seconds(0.6))
                }
            }
        }
    }

    private func commitRename() {
        petCollectionViewModel.renameActivePet(to: editedName)
        isEditingName = false
    }

    private func triggerSparkle() {
        isLevelingUp = true
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            isLevelingUp = false
        }
    }

    private func triggerHearts() {
        isShowingHearts = true
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            isShowingHearts = false
        }
    }

    private func triggerSquish() {
        isSquishing = true
        Task {
            try? await Task.sleep(for: .seconds(0.15))
            isSquishing = false
        }
    }

    private func performWiggle() async {
        let angles: [Double] = [-8, 8, -6, 6, -3, 0]
        for angle in angles {
            withAnimation(.easeInOut(duration: 0.06)) {
                wiggleAngle = angle
            }
            try? await Task.sleep(for: .seconds(0.06))
        }
    }
}

struct FriendshipMeterView: View {
    let level: Int
    var size: CGFloat = 14

    private static let maxLevel = 10

    private var fraction: CGFloat {
        CGFloat(min(max(level, 0), Self.maxLevel)) / CGFloat(Self.maxLevel)
    }

    var body: some View {
        ZStack {
            Image(systemName: "heart")
                .font(.system(size: size))
                .foregroundStyle(Color.secondary.opacity(0.3))

            Image(systemName: "heart.fill")
                .font(.system(size: size))
                .foregroundStyle(Color.pink)
                .mask(
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        Rectangle().frame(height: size * fraction)
                    }
                    .frame(height: size)
                )
        }
        .frame(width: size, height: size)
    }
}

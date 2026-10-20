import Foundation

enum PetReaction: Equatable {
    case hatch
    case levelUp
    case evolve
    case shiny
    case hearts
}

final class PetCollectionViewModel: ObservableObject {
    @Published private(set) var state: PetCollectionState
    @Published private(set) var reactionTick: Int = 0
    @Published private(set) var pendingReactions: [PetReaction] = []
    @Published private(set) var unlockRevealTick: Int = 0
    @Published private(set) var lastRevealedLineID: String?
    @Published private(set) var pendingShinyClaimLineID: String?
    @Published private(set) var pendingAutoUnlockID: String?
    @Published private(set) var activationTick: Int = 0

    var pendingShinyClaim: Bool { pendingShinyClaimLineID != nil }

    var pendingAutoUnlockDisplayName: String? {
        guard let id = pendingAutoUnlockID else { return nil }
        return Gen1Roster.line(for: id)?.displayName
    }

    private let store: PetCollectionStore
    private let unlockRules: GenerationUnlockRules = Gen1UnlockRules()
    private static let maxFriendshipLevel = 10
    private static let friendshipDecayInterval: TimeInterval = 12 * 60 * 60

    init(store: PetCollectionStore = PetCollectionStore()) {
        self.store = store
        if let loaded = store.load() {
            self.state = loaded
        } else {
            var fresh = PetCollectionState()
            for id in Gen1Roster.starterIDs {
                fresh.progressByLineID[id] = PetProgress(level: 0)
            }
            fresh.activeLineID = Gen1Roster.starterIDs[0]
            self.state = fresh
            store.save(fresh)
        }
        checkFriendshipDecay()
    }

    var activeLine: PokemonLine {
        Gen1Roster.line(for: state.activeLineID)!
    }

    var activeProgress: PetProgress {
        state.progressByLineID[state.activeLineID] ?? PetProgress()
    }

    var knownLines: [PokemonLine] {
        let orderedIDs = Gen1Roster.starterIDs + Gen1Roster.birdIDs + [Gen1Roster.mewtwoID, Gen1Roster.mewID]
        return orderedIDs.compactMap { id in
            guard state.progressByLineID[id] != nil else { return nil }
            return Gen1Roster.line(for: id)
        }
    }

    var lockedBirdLines: [PokemonLine] {
        Gen1Roster.birdIDs.compactMap { id in
            state.progressByLineID[id] == nil ? Gen1Roster.line(for: id) : nil
        }
    }

    var hasPendingLegendaryPick: Bool {
        Gen1Roster.starterIDs.contains { state.progressByLineID[$0]?.legendaryPickPending == true }
    }

    func progress(for lineID: String) -> PetProgress {
        state.progressByLineID[lineID] ?? PetProgress()
    }

    var activeDisplayName: String {
        displayName(for: state.activeLineID)
    }

    func displayName(for lineID: String) -> String {
        let progress = state.progressByLineID[lineID]
        if let nickname = progress?.nickname, !nickname.isEmpty {
            return nickname
        }
        guard let line = Gen1Roster.line(for: lineID) else { return lineID }
        // Reflects the current evolution stage (e.g. "Wartortle" after evolving from Squirtle)
        // rather than always the line's base species name.
        return line.stage(for: progress?.level ?? 0).displayName
    }

    func starredDisplayName(for lineID: String) -> String {
        let name = displayName(for: lineID)
        return state.progressByLineID[lineID]?.isShiny == true ? "★ \(name)" : name
    }

    var activeStarredDisplayName: String {
        starredDisplayName(for: state.activeLineID)
    }

    func renameActivePet(to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var progress = state.progressByLineID[state.activeLineID] else { return }
        progress.nickname = trimmed.isEmpty ? nil : trimmed
        state.progressByLineID[state.activeLineID] = progress
        persist()
    }

    func setActive(_ lineID: String) {
        guard var progress = state.progressByLineID[lineID] else { return }
        // A pet's friendship clock only runs while it's active -- restarting it here
        // means time spent inactive in the PC Box never counts against it.
        progress.friendshipAnchorAt = Date()
        state.progressByLineID[lineID] = progress
        state.activeLineID = lineID
        persist()
        activationTick += 1
    }

    func registerCompletion() {
        guard var progress = state.progressByLineID[state.activeLineID] else { return }
        let line = activeLine

        if progress.level >= 100 && !progress.hasPrestiged {
            pendingShinyClaimLineID = state.activeLineID
            return
        }

        var reactions: [PetReaction] = []

        let stageIndexBefore = line.stageIndex(for: progress.level)

        if progress.level == 0 {
            progress.level = 1
            reactions.append(.hatch)
        } else {
            progress.level = min(100, progress.level + 1)
            reactions.append(.levelUp)
        }

        let stageIndexAfter = line.stageIndex(for: progress.level)
        if let before = stageIndexBefore, let after = stageIndexAfter, after > before {
            reactions.append(.evolve)
        }

        if progress.level >= 50 && progress.level % 10 == 0 {
            reactions.append(.hearts)
        }

        applyFriendshipIncrement(to: &progress, reactions: &reactions)

        if line.role == .starter && progress.level == 50 && !progress.isShiny {
            progress.legendaryPickPending = true
        }

        state.progressByLineID[state.activeLineID] = progress

        if hasPendingLegendaryPick && lockedBirdLines.isEmpty {
            for starterID in Gen1Roster.starterIDs {
                state.progressByLineID[starterID]?.legendaryPickPending = false
            }
        }

        if pendingAutoUnlockID == nil, let candidate = unlockRules.nextAutoUnlockCandidate(in: state) {
            pendingAutoUnlockID = candidate
        }

        persist()
        pendingReactions = reactions
        reactionTick += 1
    }

    /// Bumps friendship by 1 (capped at `maxFriendshipLevel`), resets the streak clock to now,
    /// and queues a `.hearts` reaction on the exact tick friendship first reaches max.
    private func applyFriendshipIncrement(to progress: inout PetProgress, reactions: inout [PetReaction]) {
        let wasFriendshipMaxed = progress.friendshipLevel >= Self.maxFriendshipLevel
        progress.friendshipLevel = min(Self.maxFriendshipLevel, progress.friendshipLevel + 1)
        progress.friendshipAnchorAt = Date()
        if progress.friendshipLevel >= Self.maxFriendshipLevel && !wasFriendshipMaxed && !reactions.contains(.hearts) {
            reactions.append(.hearts)
        }
    }

    func resetActivePet() {
        guard var progress = state.progressByLineID[state.activeLineID] else { return }
        progress.level = activeLine.hasEgg ? 0 : 1
        progress.legendaryPickPending = false
        progress.isShiny = false
        progress.hasPrestiged = false
        progress.friendshipLevel = 0
        progress.friendshipAnchorAt = nil
        state.progressByLineID[state.activeLineID] = progress
        persist()
    }

    /// Applies any friendship decay owed to the active pet since its clock was last checked.
    /// Only the active pet's clock ever runs -- an inactive pet's `friendshipAnchorAt` is left
    /// untouched here, so time spent away from it is never counted against it (see `setActive`).
    func checkFriendshipDecay() {
        guard var progress = state.progressByLineID[state.activeLineID] else { return }
        guard let anchor = progress.friendshipAnchorAt else {
            progress.friendshipAnchorAt = Date()
            state.progressByLineID[state.activeLineID] = progress
            persist()
            return
        }

        var elapsed = Date().timeIntervalSince(anchor)
        guard elapsed >= Self.friendshipDecayInterval, progress.friendshipLevel > 0 else { return }

        var newAnchor = anchor
        while elapsed >= Self.friendshipDecayInterval && progress.friendshipLevel > 0 {
            progress.friendshipLevel -= 1
            newAnchor = newAnchor.addingTimeInterval(Self.friendshipDecayInterval)
            elapsed -= Self.friendshipDecayInterval
        }
        progress.friendshipAnchorAt = newAnchor
        state.progressByLineID[state.activeLineID] = progress
        persist()
    }

    func resetEntireCollection() {
        var fresh = PetCollectionState()
        for id in Gen1Roster.starterIDs {
            fresh.progressByLineID[id] = PetProgress(level: 0)
        }
        fresh.activeLineID = Gen1Roster.starterIDs[0]
        state = fresh
        pendingShinyClaimLineID = nil
        pendingAutoUnlockID = nil
        persist()
        activationTick += 1
    }

    func claimShiny() {
        guard let lineID = pendingShinyClaimLineID,
              var progress = state.progressByLineID[lineID],
              progress.level == 100, !progress.hasPrestiged else {
            pendingShinyClaimLineID = nil
            return
        }
        progress.isShiny = true
        progress.hasPrestiged = true
        progress.level = 1
        progress.legendaryPickPending = false
        progress.friendshipLevel = 0
        progress.friendshipAnchorAt = nil
        state.progressByLineID[lineID] = progress
        persist()
        pendingShinyClaimLineID = nil
        pendingReactions = [.shiny]
        reactionTick += 1
    }

    func declineShinyClaim() {
        pendingShinyClaimLineID = nil
    }

    func claimAutoUnlock() {
        guard let lineID = pendingAutoUnlockID else { return }
        state.progressByLineID[lineID] = PetProgress(level: 1)
        state.activeLineID = lineID
        persist()
        pendingAutoUnlockID = nil
        lastRevealedLineID = lineID
        unlockRevealTick += 1
        pendingReactions = [.evolve]
        reactionTick += 1
        activationTick += 1
    }

    func declineAutoUnlockClaim() {
        pendingAutoUnlockID = nil
    }

    func choosePendingLegendaryBird(_ birdID: String) {
        guard state.progressByLineID[birdID] == nil, Gen1Roster.birdIDs.contains(birdID) else { return }
        for starterID in Gen1Roster.starterIDs {
            if state.progressByLineID[starterID]?.legendaryPickPending == true {
                state.progressByLineID[starterID]?.legendaryPickPending = false
                break
            }
        }
        state.progressByLineID[birdID] = PetProgress(level: 1)
        state.activeLineID = birdID
        persist()
        lastRevealedLineID = birdID
        unlockRevealTick += 1
        activationTick += 1
    }

    static func spriteResourceName(for line: PokemonLine, progress: PetProgress) -> String {
        guard progress.level > 0 else { return "egg" }
        let stage = line.stage(for: progress.level)
        return progress.isShiny ? stage.shinySpriteName : stage.normalSpriteName
    }

    private func persist() {
        store.save(state)
    }
}

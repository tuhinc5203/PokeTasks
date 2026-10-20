enum PokemonRole {
    case starter
    case legendaryBird
    case mewtwo
    case mew
}

struct EvolutionStage {
    let minLevel: Int
    let displayName: String
    let normalSpriteName: String
    let shinySpriteName: String
}

struct PokemonLine: Identifiable {
    let id: String
    let displayName: String
    let role: PokemonRole
    let hasEgg: Bool
    let stages: [EvolutionStage]

    func stage(for level: Int) -> EvolutionStage {
        var current = stages[0]
        for stage in stages where level >= stage.minLevel {
            current = stage
        }
        return current
    }

    func stageIndex(for level: Int) -> Int? {
        guard level > 0 else { return nil }
        var index = 0
        for (i, stage) in stages.enumerated() where level >= stage.minLevel {
            index = i
        }
        return index
    }
}

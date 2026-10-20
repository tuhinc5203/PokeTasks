protocol GenerationUnlockRules {
    /// Returns the id of a not-yet-unlocked line whose auto-unlock criteria are now met, if any.
    /// A pure query -- the caller decides whether/when to actually insert it (e.g. behind a claim confirmation).
    func nextAutoUnlockCandidate(in state: PetCollectionState) -> String?
}

enum Gen1Roster {
    static let starterIDs = ["bulbasaur", "charmander", "squirtle"]
    static let birdIDs = ["zapdos", "articuno", "moltres"]
    static let mewtwoID = "mewtwo"
    static let mewID = "mew"

    static let allLines: [PokemonLine] = [
        PokemonLine(
            id: "bulbasaur",
            displayName: "Bulbasaur",
            role: .starter,
            hasEgg: true,
            stages: [
                EvolutionStage(minLevel: 1, displayName: "Bulbasaur", normalSpriteName: "bulbasaur", shinySpriteName: "bulbasaur_shiny"),
                EvolutionStage(minLevel: 16, displayName: "Ivysaur", normalSpriteName: "ivysaur", shinySpriteName: "ivysaur_shiny"),
                EvolutionStage(minLevel: 32, displayName: "Venusaur", normalSpriteName: "venusaur", shinySpriteName: "venusaur_shiny"),
            ]
        ),
        PokemonLine(
            id: "charmander",
            displayName: "Charmander",
            role: .starter,
            hasEgg: true,
            stages: [
                EvolutionStage(minLevel: 1, displayName: "Charmander", normalSpriteName: "charmander", shinySpriteName: "charmander_shiny"),
                EvolutionStage(minLevel: 16, displayName: "Charmeleon", normalSpriteName: "charmeleon", shinySpriteName: "charmeleon_shiny"),
                EvolutionStage(minLevel: 36, displayName: "Charizard", normalSpriteName: "charizard", shinySpriteName: "charizard_shiny"),
            ]
        ),
        PokemonLine(
            id: "squirtle",
            displayName: "Squirtle",
            role: .starter,
            hasEgg: true,
            stages: [
                EvolutionStage(minLevel: 1, displayName: "Squirtle", normalSpriteName: "squirtle", shinySpriteName: "squirtle_shiny"),
                EvolutionStage(minLevel: 16, displayName: "Wartortle", normalSpriteName: "wartortle", shinySpriteName: "wartortle_shiny"),
                EvolutionStage(minLevel: 36, displayName: "Blastoise", normalSpriteName: "blastoise", shinySpriteName: "blastoise_shiny"),
            ]
        ),
        PokemonLine(
            id: "zapdos",
            displayName: "Zapdos",
            role: .legendaryBird,
            hasEgg: false,
            stages: [EvolutionStage(minLevel: 1, displayName: "Zapdos", normalSpriteName: "zapdos", shinySpriteName: "zapdos_shiny")]
        ),
        PokemonLine(
            id: "articuno",
            displayName: "Articuno",
            role: .legendaryBird,
            hasEgg: false,
            stages: [EvolutionStage(minLevel: 1, displayName: "Articuno", normalSpriteName: "articuno", shinySpriteName: "articuno_shiny")]
        ),
        PokemonLine(
            id: "moltres",
            displayName: "Moltres",
            role: .legendaryBird,
            hasEgg: false,
            stages: [EvolutionStage(minLevel: 1, displayName: "Moltres", normalSpriteName: "moltres", shinySpriteName: "moltres_shiny")]
        ),
        PokemonLine(
            id: "mewtwo",
            displayName: "Mewtwo",
            role: .mewtwo,
            hasEgg: false,
            stages: [EvolutionStage(minLevel: 1, displayName: "Mewtwo", normalSpriteName: "mewtwo", shinySpriteName: "mewtwo_shiny")]
        ),
        PokemonLine(
            id: "mew",
            displayName: "Mew",
            role: .mew,
            hasEgg: false,
            stages: [EvolutionStage(minLevel: 1, displayName: "Mew", normalSpriteName: "mew", shinySpriteName: "mew_shiny")]
        ),
    ]

    static func line(for id: String) -> PokemonLine? {
        allLines.first { $0.id == id }
    }
}

struct Gen1UnlockRules: GenerationUnlockRules {
    func nextAutoUnlockCandidate(in state: PetCollectionState) -> String? {
        if state.progressByLineID[Gen1Roster.mewtwoID] == nil {
            let allBirdsReady = Gen1Roster.birdIDs.allSatisfy { id in
                (state.progressByLineID[id]?.level ?? 0) >= 50
            }
            if allBirdsReady {
                return Gen1Roster.mewtwoID
            }
        }

        if state.progressByLineID[Gen1Roster.mewID] == nil {
            let mewtwoReady = (state.progressByLineID[Gen1Roster.mewtwoID]?.level ?? 0) >= 50
            if mewtwoReady {
                return Gen1Roster.mewID
            }
        }

        return nil
    }
}

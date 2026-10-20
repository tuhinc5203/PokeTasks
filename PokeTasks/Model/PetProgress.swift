import Foundation

struct PetProgress: Codable {
    var level: Int = 0
    var isShiny: Bool = false
    var hasPrestiged: Bool = false
    var legendaryPickPending: Bool = false
    var nickname: String? = nil
    var friendshipLevel: Int = 0
    var friendshipAnchorAt: Date? = nil

    init(
        level: Int = 0,
        isShiny: Bool = false,
        hasPrestiged: Bool = false,
        legendaryPickPending: Bool = false,
        nickname: String? = nil,
        friendshipLevel: Int = 0,
        friendshipAnchorAt: Date? = nil
    ) {
        self.level = level
        self.isShiny = isShiny
        self.hasPrestiged = hasPrestiged
        self.legendaryPickPending = legendaryPickPending
        self.nickname = nickname
        self.friendshipLevel = friendshipLevel
        self.friendshipAnchorAt = friendshipAnchorAt
    }

    private enum CodingKeys: String, CodingKey {
        case level, isShiny, hasPrestiged, legendaryPickPending, nickname, friendshipLevel, friendshipAnchorAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 0
        isShiny = try container.decodeIfPresent(Bool.self, forKey: .isShiny) ?? false
        hasPrestiged = try container.decodeIfPresent(Bool.self, forKey: .hasPrestiged) ?? false
        legendaryPickPending = try container.decodeIfPresent(Bool.self, forKey: .legendaryPickPending) ?? false
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        // Older saved progress predates the friendship meter -- default to an unstarted meter.
        friendshipLevel = try container.decodeIfPresent(Int.self, forKey: .friendshipLevel) ?? 0
        friendshipAnchorAt = try container.decodeIfPresent(Date.self, forKey: .friendshipAnchorAt)
    }
}

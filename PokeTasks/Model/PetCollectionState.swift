struct PetCollectionState: Codable {
    var progressByLineID: [String: PetProgress] = [:]
    var activeLineID: String = ""
}

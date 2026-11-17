import Foundation

struct Hero: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var aspect: String
    var isOwned = true
    var isFavourite = false
}

struct Scenario: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var difficulty: String
    var notes: String = ""
}

struct PlayRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var heroName: String
    var villainName: String
    var result: String
    var difficulty: String
    var playedAt = Date()
}

struct Deck: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var heroName: String
    var aspect: String
    var notes: String = ""
}

struct CollectionItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var category: String
    var isOwned = false
}

struct TrackerData: Codable {
    var heroes: [Hero] = []
    var scenarios: [Scenario] = []
    var records: [PlayRecord] = []
    var decks: [Deck] = []
    var collection: [CollectionItem] = []
}

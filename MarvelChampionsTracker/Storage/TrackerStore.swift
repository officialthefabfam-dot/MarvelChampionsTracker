import Foundation
import SwiftUI

@MainActor
final class TrackerStore: ObservableObject {
    @Published private(set) var data: TrackerData

    private let fileURL: URL

    // Master catalogue. Existing ownership choices are preserved when this list grows.
    private static let collectionCatalogue: [CollectionItem] = {
        let heroPacks = [
            "Captain America", "Ms. Marvel", "Thor", "Black Widow", "Doctor Strange", "Hulk",
            "Ant-Man", "Wasp", "Quicksilver", "Scarlet Witch", "Star-Lord", "Gamora", "Drax",
            "Venom", "Nebula", "War Machine", "Valkyrie", "Vision", "Nova", "Ironheart",
            "Spider-Ham", "SP//dr", "Cyclops", "Phoenix", "Wolverine", "Storm", "Gambit",
            "Rogue", "Psylocke", "Angel", "X-23", "Deadpool", "Iceman", "Jubilee",
            "Nightcrawler", "Magneto", "Black Panther (Shuri)", "Silk", "Falcon",
            "Winter Soldier", "Wonder Man", "Hercules", "Jessica Jones", "Luke Cage",
            "Elektra", "Iron Fist"
        ].map { CollectionItem(name: $0, category: "Hero pack") }

        let campaigns = [
            "Core Set", "The Rise of Red Skull", "The Galaxy's Most Wanted",
            "The Mad Titan's Shadow", "Sinister Motives", "Mutant Genesis",
            "NeXt Evolution", "Age of Apocalypse", "Agents of S.H.I.E.L.D.",
            "Civil War", "Fear No Evil", "Captain America"
        ].map { CollectionItem(name: $0, category: "Campaign / expansion") }

        let scenarios = [
            "The Green Goblin", "The Wrecking Crew", "The Once and Future Kang",
            "The Hood", "MojoMania", "Trickster Takeover", "Synthezoid Smackdown",
            "Shadowland"
        ].map { CollectionItem(name: $0, category: "Scenario pack") }

        return campaigns + heroPacks + scenarios
    }()

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("champions-tracker.json")
        if let contents = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(TrackerData.self, from: contents) {
            // Merge in newly catalogued products without resetting anything the player has tracked.
            var migrated = saved
            let existingNames = Set(saved.collection.map { $0.name.localizedLowercase })
            let additions = Self.collectionCatalogue.filter {
                !existingNames.contains($0.name.localizedLowercase)
            }
            migrated.collection.append(contentsOf: additions)
            data = migrated
            if !additions.isEmpty { persist() }
        } else {
            data = TrackerData(
                heroes: [
                    Hero(name: "Spider-Man", aspect: "Protection", isOwned: false),
                    Hero(name: "Captain Marvel", aspect: "Leadership", isOwned: false),
                    Hero(name: "Black Panther", aspect: "Justice", isOwned: false),
                    Hero(name: "Iron Man", aspect: "Aggression", isOwned: false)
                ],
                scenarios: [
                    Scenario(name: "Rhino", difficulty: "Standard"),
                    Scenario(name: "Klaw", difficulty: "Standard"),
                    Scenario(name: "Ultron", difficulty: "Standard")
                ],
                collection: Self.collectionCatalogue
            )
            persist()
        }
    }

    var ownedHeroes: [Hero] { data.heroes.filter(\.isOwned) }
    var winCount: Int { data.records.filter { $0.result == "Win" }.count }
    var lossCount: Int { data.records.filter { $0.result == "Loss" }.count }
    var winRate: Int {
        let total = winCount + lossCount
        return total == 0 ? 0 : Int((Double(winCount) / Double(total) * 100).rounded())
    }

    func addHero(name: String, aspect: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var next = data
        next.heroes.append(Hero(name: name.trimmingCharacters(in: .whitespaces), aspect: aspect))
        data = next
        persist()
    }

    func toggleFavourite(_ hero: Hero) {
        var next = data
        guard let index = next.heroes.firstIndex(where: { $0.id == hero.id }) else { return }
        next.heroes[index].isFavourite.toggle()
        data = next
        persist()
    }

    func toggleOwned(_ item: CollectionItem) {
        var next = data
        guard let index = next.collection.firstIndex(where: { $0.id == item.id }) else { return }
        next.collection[index].isOwned.toggle()
        data = next
        persist()
    }

    func addScenario(name: String, difficulty: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var next = data
        next.scenarios.append(Scenario(name: name, difficulty: difficulty))
        data = next
        persist()
    }

    func addRecord(hero: String, villain: String, result: String, difficulty: String) {
        var next = data
        next.records.insert(PlayRecord(heroName: hero, villainName: villain, result: result, difficulty: difficulty), at: 0)
        data = next
        persist()
    }

    func addDeck(name: String, hero: String, aspect: String, notes: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var next = data
        next.decks.insert(Deck(name: name, heroName: hero, aspect: aspect, notes: notes), at: 0)
        data = next
        persist()
    }

    func exportBackup() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ChampionsTracker-Backup.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(data).write(to: url, options: .atomic)
        return url
    }

    func importBackup(from url: URL) throws {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let imported = try JSONDecoder().decode(TrackerData.self, from: Data(contentsOf: url))
        data = imported
        persist()
    }

    private func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(data).write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Could not save tracker data: \(error)")
        }
    }
}

import Foundation
import SwiftUI

@MainActor
final class TrackerStore: ObservableObject {
    @Published private(set) var data: TrackerData

    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("champions-tracker.json")
        if let contents = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(TrackerData.self, from: contents) {
            data = saved
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
                collection: [
                    CollectionItem(name: "Core Set", category: "Core Set"),
                    CollectionItem(name: "Rise of Red Skull", category: "Campaign"),
                    CollectionItem(name: "Galaxy's Most Wanted", category: "Campaign"),
                    CollectionItem(name: "Mad Titan's Shadow", category: "Campaign"),
                    CollectionItem(name: "Sinister Motives", category: "Campaign"),
                    CollectionItem(name: "Mutant Genesis", category: "Campaign")
                ]
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

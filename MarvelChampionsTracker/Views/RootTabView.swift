import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct RootTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Overview", systemImage: "square.grid.2x2.fill") }
            HeroesView()
                .tabItem { Label("Heroes", systemImage: "person.3.fill") }
            VillainsView()
                .tabItem { Label("Villains", systemImage: "shield.lefthalf.filled") }
            DecksView()
                .tabItem { Label("Decks", systemImage: "rectangle.stack.fill") }
            CollectionView()
                .tabItem { Label("Collection", systemImage: "shippingbox.fill") }
        }
        .preferredColorScheme(.light)
    }
}

struct ScreenBackground<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        content
                    }
                    .padding(18)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.navy.opacity(0.06), lineWidth: 1))
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color
    var body: some View {
        Panel {
            Image(systemName: symbol).font(.title3).foregroundStyle(tint)
            Text(value).font(.system(size: 27, weight: .bold, design: .rounded)).foregroundStyle(Theme.navy)
            Text(title).font(.caption).foregroundStyle(Theme.muted)
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: TrackerStore
    @State private var showingRecord = false
    @State private var showingBackup = false
    @State private var backupURL: URL?
    @State private var showingImporter = false
    @State private var errorMessage: String?

    var body: some View {
        ScreenBackground(title: "Command Centre") {
            VStack(alignment: .leading, spacing: 5) {
                Text("MARVEL CHAMPIONS").font(.caption.weight(.bold)).tracking(2).foregroundStyle(Theme.red)
                Text("Your next chapter starts here.").font(.title3.weight(.semibold)).foregroundStyle(Theme.navy)
            }
            HStack(spacing: 10) {
                StatTile(title: "Heroes owned", value: "\(store.ownedHeroes.count)", symbol: "person.fill", tint: Theme.blue)
                StatTile(title: "Win rate", value: "\(store.winRate)%", symbol: "chart.line.uptrend.xyaxis", tint: Theme.gold)
            }
            HStack(spacing: 10) {
                StatTile(title: "Victories", value: "\(store.winCount)", symbol: "trophy.fill", tint: Theme.gold)
                StatTile(title: "Decks saved", value: "\(store.data.decks.count)", symbol: "rectangle.stack.fill", tint: Theme.red)
            }
            Panel {
                HStack {
                    Text("Quick actions").font(.headline).foregroundStyle(Theme.navy)
                    Spacer()
                    Image(systemName: "bolt.fill").foregroundStyle(Theme.gold)
                }
                Button { showingRecord = true } label: {
                    Label("Record a game", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity).padding(13)
                        .background(Theme.navy, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                Button { showingImporter = true } label: {
                    Label("Restore from backup", systemImage: "arrow.down.doc")
                        .frame(maxWidth: .infinity).padding(12)
                        .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Theme.navy)
                }
                .buttonStyle(.plain)
                Button {
                    do { backupURL = try store.exportBackup(); showingBackup = true }
                    catch { errorMessage = error.localizedDescription }
                } label: {
                    Label("Export backup", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity).padding(12)
                        .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Theme.navy)
                }
                .buttonStyle(.plain)
            }
            Panel {
                Text("Recent games").font(.headline).foregroundStyle(Theme.navy)
                if store.data.records.isEmpty {
                    EmptyMessage(text: "Your game history will appear here once you record your first session.")
                } else {
                    ForEach(store.data.records.prefix(5)) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(record.heroName) vs \(record.villainName)").font(.subheadline.weight(.semibold))
                                Text("\(record.difficulty) · \(record.playedAt.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Text(record.result.uppercased()).font(.caption2.weight(.bold))
                                .foregroundStyle(record.result == "Win" ? Theme.gold : Theme.red)
                        }
                        Divider()
                    }
                }
            }
        }
        .sheet(isPresented: $showingRecord) { RecordGameSheet() }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
            do { try store.importBackup(from: result.get()) }
            catch { errorMessage = error.localizedDescription }
        }
        .sheet(isPresented: $showingBackup) {
            if let backupURL {
                ShareSheet(items: [backupURL])
                    .presentationDetents([.medium])
            }
        }
        .alert("Backup issue", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }
}

struct HeroesView: View {
    @EnvironmentObject private var store: TrackerStore
    @State private var showingAdd = false
    var body: some View {
        ScreenBackground(title: "Heroes") {
            Panel {
                Text("Your roster").font(.headline).foregroundStyle(Theme.navy)
                Text("Track your collection and mark the heroes you reach for most.").font(.subheadline).foregroundStyle(Theme.muted)
                ForEach(store.data.heroes) { hero in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Theme.canvas).frame(width: 48, height: 48)
                            Image(systemName: "person.crop.square.fill").font(.title2).foregroundStyle(Theme.blue)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(hero.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.navy)
                            Text(hero.aspect + (hero.isOwned ? " · Owned" : " · Not owned")).font(.caption).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        Button { store.toggleFavourite(hero) } label: {
                            Image(systemName: hero.isFavourite ? "star.fill" : "star").foregroundStyle(Theme.gold)
                        }.buttonStyle(.plain)
                    }
                    Divider()
                }
                Button { showingAdd = true } label: {
                    Label("Add a hero", systemImage: "plus").frame(maxWidth: .infinity).padding(12)
                        .background(Theme.navy, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.white)
                }.buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingAdd) { AddHeroSheet() }
    }
}

struct VillainsView: View {
    @EnvironmentObject private var store: TrackerStore
    @State private var showingAdd = false
    @State private var showingRecord = false
    var body: some View {
        ScreenBackground(title: "Villains") {
            Panel {
                Text("Scenario library").font(.headline).foregroundStyle(Theme.navy)
                Text("Keep track of encounters and log every outcome.").font(.subheadline).foregroundStyle(Theme.muted)
                ForEach(store.data.scenarios) { scenario in
                    HStack {
                        Image(systemName: "shield.fill").foregroundStyle(Theme.red)
                        VStack(alignment: .leading) {
                            Text(scenario.name).font(.subheadline.weight(.semibold))
                            Text(scenario.difficulty).font(.caption).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                    }
                    Divider()
                }
                Button { showingAdd = true } label: {
                    Label("Add scenario", systemImage: "plus").frame(maxWidth: .infinity).padding(12)
                        .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(Theme.navy)
                }.buttonStyle(.plain)
                Button { showingRecord = true } label: {
                    Label("Log a game", systemImage: "checkmark.circle.fill").frame(maxWidth: .infinity).padding(12)
                        .background(Theme.navy, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.white)
                }.buttonStyle(.plain)
            }
            Panel {
                Text("Results").font(.headline).foregroundStyle(Theme.navy)
                HStack {
                    Label("\(store.winCount) wins", systemImage: "trophy.fill").foregroundStyle(Theme.gold)
                    Spacer()
                    Label("\(store.lossCount) losses", systemImage: "xmark.circle.fill").foregroundStyle(Theme.red)
                }
            }
        }
        .sheet(isPresented: $showingAdd) { AddScenarioSheet() }
        .sheet(isPresented: $showingRecord) { RecordGameSheet() }
    }
}

struct DecksView: View {
    @EnvironmentObject private var store: TrackerStore
    @State private var showingAdd = false
    var body: some View {
        ScreenBackground(title: "Deck Library") {
            Panel {
                Text("Saved decks").font(.headline).foregroundStyle(Theme.navy)
                if store.data.decks.isEmpty {
                    EmptyMessage(text: "Build your library by saving your first hero deck.")
                }
                ForEach(store.data.decks) { deck in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(deck.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.navy)
                        Text("\(deck.heroName) · \(deck.aspect)").font(.caption).foregroundStyle(Theme.muted)
                        if !deck.notes.isEmpty { Text(deck.notes).font(.caption).foregroundStyle(Theme.muted) }
                    }
                    Divider()
                }
                Button { showingAdd = true } label: {
                    Label("Create a deck", systemImage: "plus").frame(maxWidth: .infinity).padding(12)
                        .background(Theme.navy, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.white)
                }.buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingAdd) { AddDeckSheet() }
    }
}

struct CollectionView: View {
    @EnvironmentObject private var store: TrackerStore
    @State private var searchText = ""

    private let categories = ["Campaign / expansion", "Hero pack", "Scenario pack"]

    private var filteredItems: [CollectionItem] {
        guard !searchText.isEmpty else { return store.data.collection }
        return store.data.collection.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScreenBackground(title: "Collection") {
            Panel {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your collection").font(.headline).foregroundStyle(Theme.navy)
                        Text("Track every box and pack you own.").font(.subheadline).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Image(systemName: "shippingbox.fill").font(.title2).foregroundStyle(Theme.gold)
                }
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.gold)
                    Text("\(store.data.collection.filter(\.isOwned).count) / \(store.data.collection.count) owned")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.navy)
                    Spacer()
                    Text("\(store.data.collection.isEmpty ? 0 : Int(Double(store.data.collection.filter(\.isOwned).count) / Double(store.data.collection.count) * 100))%")
                        .font(.caption.weight(.bold)).foregroundStyle(Theme.blue)
                }
                GeometryReader { geometry in
                    let total = max(store.data.collection.count, 1)
                    let owned = store.data.collection.filter(\.isOwned).count
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.canvas)
                        Capsule().fill(Theme.gold).frame(width: geometry.size.width * CGFloat(owned) / CGFloat(total))
                    }
                }
                .frame(height: 8)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.muted)
                TextField("Find a pack or expansion", text: $searchText)
                    .textInputAutocapitalization(.never)
            }
            .padding(12)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))

            ForEach(categories, id: \.self) { category in
                let items = filteredItems.filter { $0.category == category }.sorted { $0.name < $1.name }
                if !items.isEmpty {
                    Panel {
                        HStack {
                            Text(category).font(.headline).foregroundStyle(Theme.navy)
                            Spacer()
                            Text("\(items.filter(\.isOwned).count)/\(items.count)")
                                .font(.caption.weight(.semibold)).foregroundStyle(Theme.blue)
                        }
                        ForEach(items) { item in
                            Button { store.toggleOwned(item) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: item.isOwned ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(item.isOwned ? Theme.gold : Theme.muted)
                                    Text(item.name)
                                        .foregroundStyle(Theme.navy)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    if item.isOwned {
                                        Text("OWNED").font(.system(size: 9, weight: .bold)).tracking(0.8)
                                            .foregroundStyle(Theme.gold)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                }
            }
            if filteredItems.isEmpty {
                Panel { EmptyMessage(text: "No matching packs found.") }
            }
        }
    }
}

struct EmptyMessage: View {
    let text: String
    var body: some View {
        Text(text).font(.subheadline).foregroundStyle(Theme.muted).padding(.vertical, 8)
    }
}

struct AddHeroSheet: View {
    @EnvironmentObject private var store: TrackerStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var aspect = "Leadership"
    private let aspects = ["Aggression", "Justice", "Leadership", "Protection", "Pool"]
    var body: some View {
        NavigationStack {
            Form {
                TextField("Hero name", text: $name)
                Picker("Aspect", selection: $aspect) { ForEach(aspects, id: \.self) { Text($0) } }
            }
            .navigationTitle("Add hero")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { store.addHero(name: name, aspect: aspect); dismiss() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) }
            }
        }
        .presentationDetents([.medium])
    }
}

struct AddScenarioSheet: View {
    @EnvironmentObject private var store: TrackerStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var difficulty = "Standard"
    var body: some View {
        NavigationStack {
            Form {
                TextField("Scenario name", text: $name)
                Picker("Difficulty", selection: $difficulty) {
                    ForEach(["Standard", "Expert", "Custom"], id: \.self) { Text($0) }
                }
            }
            .navigationTitle("Add scenario")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { store.addScenario(name: name, difficulty: difficulty); dismiss() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) }
            }
        }
        .presentationDetents([.medium])
    }
}

struct AddDeckSheet: View {
    @EnvironmentObject private var store: TrackerStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var hero = "Spider-Man"
    @State private var aspect = "Justice"
    @State private var notes = ""
    var body: some View {
        NavigationStack {
            Form {
                TextField("Deck name", text: $name)
                TextField("Hero", text: $hero)
                Picker("Aspect", selection: $aspect) {
                    ForEach(["Aggression", "Justice", "Leadership", "Protection", "Pool"], id: \.self) { Text($0) }
                }
                TextField("Notes (optional)", text: $notes, axis: .vertical)
            }
            .navigationTitle("New deck")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { store.addDeck(name: name, hero: hero, aspect: aspect, notes: notes); dismiss() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct RecordGameSheet: View {
    @EnvironmentObject private var store: TrackerStore
    @Environment(\.dismiss) private var dismiss
    @State private var hero = "Spider-Man"
    @State private var villain = "Rhino"
    @State private var result = "Win"
    @State private var difficulty = "Standard"
    var body: some View {
        NavigationStack {
            Form {
                TextField("Hero", text: $hero)
                TextField("Villain / scenario", text: $villain)
                Picker("Result", selection: $result) {
                    Text("Win").tag("Win")
                    Text("Loss").tag("Loss")
                }
                Picker("Difficulty", selection: $difficulty) {
                    ForEach(["Standard", "Expert", "Custom"], id: \.self) { Text($0) }
                }
            }
            .navigationTitle("Record a game")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { store.addRecord(hero: hero, villain: villain, result: result, difficulty: difficulty); dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

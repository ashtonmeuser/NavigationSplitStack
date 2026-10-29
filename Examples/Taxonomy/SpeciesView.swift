//
//  SpeciesView.swift
//  Taxonomy
//
//  Created by Ashton Meuser on 2026-10-28.
//

import SwiftUI
import SQLiteData
import NavigationSplitStack

@MainActor
@Observable
final class SpeciesModel {
    private enum Family: AliasName {}

    @ObservationIgnored
    @Dependency(Router.self) private var router

    @ObservationIgnored
    @FetchOne var species: Species?

    @ObservationIgnored
    @FetchOne var family: Taxon?

    @ObservationIgnored
    @FetchOne var taxonomicClass: Taxon?

    @ObservationIgnored
    @FetchAll var sameFamilySpecies: [Species]

    init(speciesID: Species.ID) {
        _species = FetchOne(
            Species.where { $0.id.is(speciesID) }
        )
        _family = FetchOne(
            Taxon
                .join(Species.where { $0.id.eq(speciesID) }) {
                    $0.id.eq($1.taxonID)
                }
                .select { family, _ in family }
        )
        _taxonomicClass = FetchOne(
            Taxon
                .join(Taxon.as(Family.self).all) {
                    $0.id.is($1.parentID)
                }
                .join(Species.where { $0.id.eq(speciesID) }) {
                    $1.id.eq($2.taxonID)
                }
                .select { taxonClass, _, _ in taxonClass }
        )
        _sameFamilySpecies = FetchAll(
            Species
                .where { $0.id.neq(speciesID) }
                .where {
                    $0.taxonID.in(Species.find(speciesID).select(\.taxonID))
                }
                .order(by: \.name),
            animation: .default
        )
    }

    func pushSpecies(_ species: Species) {
        router.detail.append(.species(species.id))
    }

    var isDetailRoot: Bool { router.detail.count <= 1 }

    func goHome() {
        router.sidebar = []
    }

    func showSidebar(_ show: Bool) {
        if show { router.showSidebar() }
        else { router.hideSidebar() }
    }

    func goToDetailRoot() {
        router.detail.removeLast(router.detail.count - 1)
    }

    func printPath() {
        print("""
            Sidebar: \(router.sidebar.map { String(describing: $0) }.joined(separator: " → "))
            Detail: \(router.detail.map { String(describing: $0) }.joined(separator: " → "))
            """)
    }

    var markdown: AttributedString? {
        guard let species, let taxonomicClass, let family else { return nil }
        return try? AttributedString(markdown: """
            The \(species.name) is a part of the [\(family.name)](taxonomy://family) \
            family within the [\(taxonomicClass.name)](taxonomy://class) class.
            """)
    }

    func openURL(_ url: URL) -> OpenURLAction.Result {
        // A better URL format could be used to navigation to an arbitrary class, family, and/or species.
        guard url.scheme == "taxonomy", let taxonomicClass, let family else { return .discarded }

        switch url.host {
        case "class":
            router.sidebar = [.class(taxonomicClass.id)]
        case "family":
            router.sidebar = [.class(taxonomicClass.id), .family(family.id)]
        default:
            return .discarded
        }

        return .handled
    }
}

struct SpeciesView: View {
    @Environment(Router.self) private var router
    @State private var model: SpeciesModel

    init(speciesID: Taxon.ID) {
        _model = State(initialValue: SpeciesModel(speciesID: speciesID))
    }

    var body: some View {
        Group {
            if let species = model.species {
                ScrollView {
                    VStack {
                        if let icon = species.icon {
                            Text(icon)
                        }
                        Text(species.name)
                        if let markdown = model.markdown {
                            Text(markdown)
                                .environment(\.openURL, OpenURLAction { model.openURL($0) } )
                        }
                        Button("Go home") {
                            model.goHome()
                        }
                        Button("Go home via env router") {
                            router.sidebar = []
                        }
//                        Button("Species ID") {
//                            print()
//                        }
                    }
                    .padding(.bottom)
                    Text("Species in same fam:")
                    ForEach(model.sameFamilySpecies) { species in
//                    List(model.sameFamilySpecies) { species in
                        Button(species.name) {
                            model.pushSpecies(species)
                        }
//                        Text(species.name)
                    }
                }
            }
        }
        .navigationTitle(model.species?.name ?? "Species")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        model.goHome()
                    } label: {
                        Label("Go Home", systemImage: "house")
                    }
                    Button {
                        model.showSidebar(true)
                    } label: {
                        Label("Show Sidebar", systemImage: "house")
                    }
                    Button {
                        model.showSidebar(false)
                    } label: {
                        Label("Hide Sidebar", systemImage: "house")
                    }
                    if !model.isDetailRoot {
                        Button {
                            model.goToDetailRoot()
                        } label: {
                            Label("Go to Detail Root", systemImage: "house")
                        }
                    }
                    Section("Debug") {
                        Button {
                            model.printPath()
                        } label: {
                            Label("Print Full Path", systemImage: "house")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

//#Preview {
//    SpeciesView()
//}

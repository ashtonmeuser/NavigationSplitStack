//
//  SpeciesView.swift
//  Taxonomy
//
//  Created by Ashton Meuser on 2026-10-28.
//

import NavigationSplitStack
import SQLiteData
import SwiftUI

@MainActor
@Observable
final class SpeciesModel {
    private enum Family: AliasName {}

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

    var alertMessage: String? {
        didSet {
            if let message = alertMessage { print(message) }
        }
    }

    var markdown: AttributedString? {
        guard let species, let taxonomicClass, let family else { return nil }
        return try? AttributedString(
            markdown: """
                The \(species.name) is a part of the **[\(family.name)](taxonomy:///\(taxonomicClass.id)/\(family.id))** \
                family within the **[\(taxonomicClass.name)](taxonomy:///\(taxonomicClass.id))** class.
                """
        )
    }

    func openURL(_ url: URL) -> [SidebarDestination]? {
        let ids = url.path.split(separator: "/").compactMap { Taxon.ID($0) }
        guard (1...2).contains(ids.count) else { return nil }
        return [.class(ids[0])] + ids.dropFirst().map { .family($0) }
    }
}

struct SpeciesView: View {
    @Environment(Router.self) private var router
    @State private var model: SpeciesModel
    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
            return .automatic
        #elseif os(iOS)
            return .topBarTrailing
        #endif
    }

    init(speciesID: Species.ID) {
        model = SpeciesModel(speciesID: speciesID)
    }

    var body: some View {
        Group {
            if let species = model.species {
                ScrollView {
                    VStack(spacing: 32) {
                        VStack {
                            if let icon = species.icon {
                                Text(icon)
                                    .font(.system(size: 120))
                            }
                            if let scientificName = species.scientificName {
                                Text(scientificName)
                                    .italic()
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let description = species.description {
                            Text(description)
                        }
                        if let markdown = model.markdown {
                            Text(markdown)
                                .environment(
                                    \.openURL,
                                    OpenURLAction {
                                        if let route = model.openURL($0) {
                                            router.sidebar = route
                                            return .handled
                                        }
                                        return .discarded
                                    }
                                )
                        }
                        if !model.sameFamilySpecies.isEmpty {
                            VStack {
                                Text("Species in the same family")
                                ForEach(model.sameFamilySpecies) { species in
                                    Button(species.name) {
                                        router.detail.append(
                                            .species(species.id)
                                        )
                                    }
                                    .fontWeight(.bold)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
        .navigationTitle(model.species?.name ?? "Species")
        .toolbar {
            ToolbarItem(placement: toolbarPlacement) {
                Menu {
                    Button {
                        router.sidebar = []
                    } label: {
                        Label("Go Home", systemImage: "house")
                    }
                    Button {
                        router.showSidebar()
                    } label: {
                        Label("Show Sidebar", systemImage: "eye")
                    }
                    Button {
                        router.hideSidebar()
                    } label: {
                        Label("Hide Sidebar", systemImage: "eye.slash")
                    }
                    if router.detail.count > 1 {
                        Button {
                            router.detail.removeLast()
                        } label: {
                            Label("Previous Species", systemImage: "arrow.left")
                        }
                    }
                    if router.detail.count > 2 {
                        Button {
                            router.detail.keepFirst(1)
                        } label: {
                            Label(
                                "Root Species",
                                systemImage: "arrow.up.folder"
                            )
                        }
                    }
                    Section("Debug") {
                        Button {
                            model.alertMessage = router.fullPath
                        } label: {
                            Label("Show Full Path", systemImage: "house")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Alert", item: $model.alertMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }
}

#Preview(traits: .dependencies { try! $0.bootstrapDatabase() }) {
    SpeciesView(speciesID: 5)
}

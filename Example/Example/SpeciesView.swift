//
//  SpeciesView.swift
//  Example
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
                .where {
                    $0.taxonID.in(Species.find(speciesID).select(\.taxonID))
                }
                .order(by: \.name),
            animation: .default
        )
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
                        if let taxonomicClass = model.taxonomicClass, let family = model.family {
                            let markdown = """
                            \(species.name) is a part of the [\(family.name)](taxonomy://family/\(family.id)) \
                            family within the [\(taxonomicClass.name)](taxonomy://class/\(taxonomicClass.id)) class.
                            """

                            Text(markdown)
                                .environment(\.openURL, OpenURLAction { url in
                                    guard url.scheme == "taxonomy",
                                          let id = Taxon.ID(url.lastPathComponent),
                                          url.path == "/\(id)"
                                    else { return .discarded }

                                    switch url.host {
                                    case "class":
                                        router.sidebar = [.class(id)]
                                    case "family":
                                        router.sidebar = [.class(taxonomicClass.id), .family(id)]
                                    default:
                                        return .discarded
                                    }

                                    return .handled
                                })
                        }
                    }
                }
            }
        }
        .navigationTitle(model.species?.name ?? "Species")
    }
}

//#Preview {
//    SpeciesView()
//}

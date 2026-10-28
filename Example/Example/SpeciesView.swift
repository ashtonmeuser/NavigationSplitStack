//
//  SpeciesView.swift
//  Example
//
//  Created by Ashton Meuser on 2026-10-28.
//

import SwiftUI
import SQLiteData

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
    @State private var model: SpeciesModel

    init(speciesID: Taxon.ID) {
        _model = State(initialValue: SpeciesModel(speciesID: speciesID))
    }

    var body: some View {
        if let species = model.species {
            ScrollView {
                VStack {
                    if let icon = species.icon {
                        Text(icon)
                    }
                    Text(species.name)
                    if let taxonomicClass = model.taxonomicClass, let family = model.family {
                        Text("\(species.name) is a part of the \(family.name) family within the \(taxonomicClass.name) class.")
                    }
                }
            }
            .navigationTitle(species.name)
        }
    }
}

//#Preview {
//    SpeciesView()
//}

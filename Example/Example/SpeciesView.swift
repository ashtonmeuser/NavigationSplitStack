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
    @ObservationIgnored
    @FetchOne var species: Species?

    init(speciesID: Species.ID) {
        _species = FetchOne(
            Species.where { $0.id.is(speciesID) }
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
            VStack {
                if let icon = species.icon {
                    Text(icon)
                }
                Text(species.name)
            }
            .navigationTitle(species.name)
        }
    }
}

//#Preview {
//    SpeciesView()
//}

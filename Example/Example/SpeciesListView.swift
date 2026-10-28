//
//  SpeciesListView.swift
//  Example
//
//  Created by Ashton Meuser on 2026-10-28.
//

import SwiftUI
import SQLiteData

@MainActor
@Observable
final class SpeciesListModel {
    @ObservationIgnored
    @FetchAll var species: [Species]

    init(taxonID: Taxon.ID) {
        _species = FetchAll(
            Species
                .where { $0.taxonID.is(taxonID) }
                .order(by: \.name),
            animation: .default
        )
    }
}

struct SpeciesListView: View {
    @State private var model: SpeciesListModel

    init(taxonID: Taxon.ID) {
        _model = State(initialValue: SpeciesListModel(taxonID: taxonID))
    }

    var body: some View {
        List(model.species) { species in
            Button(species.name) {
                
            }
//            NavigationLink(value: destination) {
//                VStack(alignment: .leading) {
//                    Text(taxon.name)
//                        .font(.headline)
//
//                    if let scientificName = taxon.scientificName {
//                        Text(scientificName)
//                            .font(.subheadline)
//                            .italic()
//                            .foregroundStyle(.secondary)
//                    }
//                }
//            }
        }
    }
}

//#Preview {
//    SpeciesListView()
//}

//
//  SpeciesListView.swift
//  Taxonomy
//
//  Created by Ashton Meuser on 2026-10-28.
//

import SwiftUI
import SQLiteData
import Dependencies
import NavigationSplitStack

@MainActor
@Observable
final class SpeciesListModel {
    @ObservationIgnored
    @Dependency(Router.self) private var router

    @ObservationIgnored
    @FetchAll var species: [Species]

    @ObservationIgnored
    @FetchOne var familyName: String

    init(taxonID: Taxon.ID) {
        _species = FetchAll(
            Species
                .where { $0.taxonID.is(taxonID) }
                .order(by: \.name),
            animation: .default
        )
        _familyName = FetchOne(
            wrappedValue: "Family",
            Taxon.where { $0.id.is(taxonID) }.select(\.name)
        )
    }

    func speciesTapped(_ id: Species.ID) {
        router.detail = [.species(id)]
    }
}

struct SpeciesListView: View {
    @State private var model: SpeciesListModel

    init(taxonID: Taxon.ID) {
        _model = State(initialValue: SpeciesListModel(taxonID: taxonID))
    }

    var body: some View {
        Group {
            if model.species.isEmpty {
                ContentUnavailableView {
                    Text("No species")
                        .foregroundStyle(.secondary)
                }
            } else {
                List(model.species) { species in
                    Button {
                        model.speciesTapped(species.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(species.name)
                                    .font(.headline)

                                if let scientificName = species.scientificName {
                                    Text(scientificName)
                                        .font(.subheadline)
                                        .italic()
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if let icon = species.icon {
                                Spacer()
                                Text(icon)
                            }
                        }

                    }
                    .tint(.primary)
                }
            }
        }
        .navigationTitle(model.familyName)
    }
}

#Preview(traits: .dependencies { try! $0.bootstrapDatabase() }) {
    SpeciesListView(taxonID: 13)
}

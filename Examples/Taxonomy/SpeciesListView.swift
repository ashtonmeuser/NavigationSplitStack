//
//  SpeciesListView.swift
//  Taxonomy
//
//  Created by Ashton Meuser on 2026-10-28.
//

import NavigationSplitStack
import SQLiteData
import SwiftUI

@MainActor
@Observable
final class SpeciesListModel {
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
}

struct SpeciesListView: View {
    @Environment(Router.self) private var router
    @State private var model: SpeciesListModel

    init(taxonID: Taxon.ID) {
        model = SpeciesListModel(taxonID: taxonID)
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
                        router.detail = [.species(species.id)]
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

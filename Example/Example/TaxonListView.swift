//
//  TaxonListView.swift
//  Example
//
//  Created by Ashton Meuser on 2026-10-28.
//

import SQLiteData
import SwiftUI

@MainActor
@Observable
final class TaxonListModel {
    @ObservationIgnored
    @FetchAll var taxa: [Taxon]

    init(parentID: Taxon.ID? = nil) {
        _taxa = FetchAll(
            Taxon
                .where { $0.parentID.is(parentID) }
                .order(by: \.name),
            animation: .default
        )
    }
}

struct TaxonListView: View {
    @State private var model: TaxonListModel

    init(parentID: Taxon.ID? = nil) {
        _model = State(initialValue: TaxonListModel(parentID: parentID))
    }

    var body: some View {
        List(model.taxa) { taxon in
            let destination = taxon.parentID == nil ? SidebarDestination.class(taxon.id) : SidebarDestination.family(taxon.id)

            NavigationLink(value: destination) {
                VStack(alignment: .leading) {
                    Text(taxon.name)
                        .font(.headline)

                    if let scientificName = taxon.scientificName {
                        Text(scientificName)
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .overlay {
            if model.$taxa.loadError != nil {
                ContentUnavailableView(
                    "Unable to Load Taxa",
                    systemImage: "exclamationmark.triangle",
                    description: Text("The taxonomy could not be read from the database.")
                )
            } else if model.taxa.isEmpty {
                if model.$taxa.isLoading {
                    ProgressView()
                } else {
                    ContentUnavailableView("No Taxa", systemImage: "leaf")
                }
            }
        }
    }
}

//#Preview {
//    TaxonListView()
//}

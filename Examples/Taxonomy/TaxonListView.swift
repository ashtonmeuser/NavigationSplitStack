//
//  TaxonListView.swift
//  Taxonomy
//
//  Created by Ashton Meuser on 2026-10-28.
//

import SQLiteData
import SwiftUI

@MainActor
@Observable
final class TaxonListModel {
    private enum ChildTaxon: AliasName {}

    @Selection
    struct TaxonWithChildCount: Identifiable {
        let taxon: Taxon
        let count: Int

        var id: Taxon.ID { taxon.id }
    }

    @ObservationIgnored
    @FetchAll var childTaxa: [TaxonWithChildCount]

    @ObservationIgnored
    @FetchOne var taxonName: String

    init(parentID: Taxon.ID? = nil) {
        _childTaxa = FetchAll(
            Taxon
                .where { $0.parentID.is(parentID) }
                .group(by: \.id)
                .order(by: \.name)
                .leftJoin(Taxon.as(ChildTaxon.self).all) {
                    $0.id.is($1.parentID)
                }
                .leftJoin(Species.all) { $0.id.eq($2.taxonID) }
                .select { taxon, childTaxon, species in
                    TaxonWithChildCount.Columns(
                        taxon: taxon,
                        count: childTaxon.id.count(distinct: true)
                            + species.id.count(distinct: true)
                    )
                },
            animation: .default
        )
        if let parentID {
            _taxonName = FetchOne(
                wrappedValue: "Taxonomy",
                Taxon.where { $0.id.eq(parentID) }.select(\.name)
            )
        } else {
            _taxonName = FetchOne(wrappedValue: "Taxonomy")
        }
    }
}

struct TaxonListView: View {
    @State private var model: TaxonListModel

    init(parentID: Taxon.ID? = nil) {
        model = TaxonListModel(parentID: parentID)
    }

    var body: some View {
        List(model.childTaxa) { taxonWithChildCount in
            let taxon = taxonWithChildCount.taxon
            let destination: SidebarDestination =
                taxon.parentID == nil ? .class(taxon.id) : .family(taxon.id)

            NavigationLink(value: destination) {
                HStack {
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
                    Spacer()
                    Text(taxonWithChildCount.count, format: .number)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(model.taxonName)
    }
}

#Preview(traits: .dependencies { try! $0.bootstrapDatabase() }) {
    TaxonListView()
}

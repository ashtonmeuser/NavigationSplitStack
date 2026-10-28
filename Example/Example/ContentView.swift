//
//  ContentView.swift
//  Example
//
//  Created by Ashton Meuser on 2026-10-28.
//

import SwiftUI
import NavigationSplitStack

enum SidebarDestination: Hashable {
    case `class`(Taxon.ID)
    case family(Taxon.ID)
}

enum DetailDestination: Hashable {
    case species(Species.ID)
}

typealias Router = NavigationSplitStackRouter<SidebarDestination, DetailDestination>

struct ContentView: View {
    @State var router = Router()

    var body: some View {
        NavigationSplitStack(router: router) { sidebarDestination in
            switch sidebarDestination {
            case .none: TaxonListView()
            case .class(let id): TaxonListView(parentID: id)
            case .family(let id): SpeciesListView(taxonID: id)
            }
        } detail: { detailDestination in
            switch detailDestination {
            case .species(let id): SpeciesView(speciesID: id)
            }
        }
    }
}

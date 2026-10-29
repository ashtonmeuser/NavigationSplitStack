//
//  Model.swift
//  Taxonomy
//
//  Created by Ashton Meuser on 2026-10-23.
//

import Foundation
import SQLiteData

@Table("taxa")
struct Taxon: Identifiable {
    let id: Int64
    let parentID: Taxon.ID?
    var name: String
    var scientificName: String?
}

@Table("species")
struct Species: Identifiable {
    let id: Int64
    let taxonID: Taxon.ID
    var name: String
    var scientificName: String?
    var icon: String?
    var description: String?
}

//
//  Model.swift
//  Taxonomy
//
//  Created by Ashton Meuser on 2026-10-23.
//

import Foundation

// MARK: Basic model
//
//struct Taxon: Identifiable, Decodable, Hashable {
//    let id: String
//    let children: [Taxon]
//    let species: [Species]
//}
//
//struct Species: Identifiable, Decodable, Hashable {
//    let id: String
//    let emoji: String?
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.singleValueContainer()
//        let raw = try container.decode(String.self)
//        id = raw.filter { !$0.isEmoji }.trimmingCharacters(in: .whitespaces)
//        let emojis = raw.filter(\.isEmoji)
//        emoji = emojis.isEmpty ? nil : emojis
//    }
//}
//
//// MARK: Protocol extensions
//
//extension Taxon: CustomStringConvertible {
//    var description: String { id }
//}
//
//extension Species: CustomStringConvertible {
//    var description: String { id }
//}
//
//// MARK: Convenience & static data extensions
//
//extension Taxon {
//    static let roots: [Taxon] = {
//        let url = Bundle.main.url(forResource: "taxonomy", withExtension: "json")!
//        let data = try! Data(contentsOf: url)
//        return try! JSONDecoder().decode([Taxon].self, from: data)
//    }()
//
//    func path(to id: Species.ID) -> [Taxon]? {
//        if species.contains(where: { $0.id == id }) {
//            return [self]
//        }
//        return children.lazy.compactMap { $0.path(to: id) }.first.map { [self] + $0 }
//    }
//
//    static func path(to id: Species.ID) -> [Taxon]? {
//        roots.lazy.compactMap { $0.path(to: id) }.first
//    }
//
//    var allSpecies: [Species] {
//        species + children.flatMap(\.allSpecies)
//    }
//
//    static let allSpecies: [Species] = roots.flatMap(\.allSpecies)
//
//    static func randomSpecies() -> Species { Taxon.allSpecies.randomElement()! }
//}
//
//extension Character {
//    var isEmoji: Bool {
//        unicodeScalars.contains {
//            $0.properties.isEmojiPresentation
//        } || (
//            unicodeScalars.count > 1 &&
//            unicodeScalars.contains { $0.properties.isEmoji }
//        )
//    }
//}
//
//










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
}

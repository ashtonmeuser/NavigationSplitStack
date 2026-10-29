//
//  TaxonomyApp.swift
//  Taxonomy
//
//  Created by Ashton Meuser on 2026-10-23.
//

import SQLiteData
import SwiftUI

@main
struct TaxonomyApp: App {
    init() {
        prepareDependencies {
            do {
                try $0.bootstrapDatabase()
            } catch {
                fatalError("Failed to bootstrap database: \(error)")
            }
        }
        print("Database:\n\(URL.applicationSupportDirectory.path(percentEncoded: false))")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

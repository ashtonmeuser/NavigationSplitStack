//
//  Database.swift
//  Taxonomy
//
//  Created by Ashton Meuser on 2026-10-28.
//

import Foundation
import SQLiteData

extension DependencyValues {
    mutating func bootstrapDatabase() throws {
        let database = try SQLiteData.defaultDatabase()
        var migrator = DatabaseMigrator()

        migrator.eraseDatabaseOnSchemaChange = true

        migrator.registerMigration("Create the 'taxa' table") { db in
            try #sql(
                """
                CREATE TABLE "taxa" (
                    "id" INTEGER PRIMARY KEY NOT NULL,
                    "parentID" INTEGER REFERENCES "taxa"("id") ON DELETE CASCADE,
                    "name" TEXT NOT NULL,
                    "scientificName" TEXT
                ) STRICT
                """
            )
            .execute(db)
        }

        migrator.registerMigration("Create the 'species' table") { db in
            try #sql(
                """
                CREATE TABLE "species" (
                    "id" INTEGER PRIMARY KEY NOT NULL,
                    "taxonID" INTEGER REFERENCES "taxa"("id") ON DELETE CASCADE,
                    "name" TEXT NOT NULL,
                    "scientificName" TEXT,
                    "icon" TEXT,
                    "description" TEXT
                ) STRICT
                """
            )
            .execute(db)
        }

        migrator.registerMigration("Seed taxonomy") { db in
            guard
                let url = Bundle.main.url(
                    forResource: "taxonomy-seed",
                    withExtension: "sql"
                )
            else {
                fatalError("Missing bundled resource: taxonomy-seed.sql")
            }
            let sql = try String(contentsOf: url, encoding: .utf8)
            try db.execute(sql: sql)
        }

        try migrator.migrate(database)
        defaultDatabase = database
    }
}

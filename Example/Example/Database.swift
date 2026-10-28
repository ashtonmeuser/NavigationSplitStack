//
//  Database.swift
//  Example
//
//  Created by Ashton Meuser on 2026-10-28.
//

import SQLiteData

extension DependencyValues {
    mutating func bootstrapDatabase() throws {
        let database = try SQLiteData.defaultDatabase()
        var migrator = DatabaseMigrator()

        #if DEBUG
            migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("Create the 'taxa' table") { db in
            try #sql(
                """
                CREATE TABLE "taxa" (
                    "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                    "parentID" TEXT REFERENCES "taxa"("id") ON DELETE CASCADE,
                    "name" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)
        }
        migrator.registerMigration("Create the 'species' table") { db in
            try #sql(
                """
                CREATE TABLE "species" (
                    "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                    "taxonID" TEXT REFERENCES "taxa"("id") ON DELETE CASCADE,
                    "name" TEXT NOT NULL,
                    "icon" TEXT
                ) STRICT
                """
            )
            .execute(db)
        }

        try migrator.migrate(database)
        defaultDatabase = database
    }
}

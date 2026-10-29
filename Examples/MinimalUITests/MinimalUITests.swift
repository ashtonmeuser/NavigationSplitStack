//
//  MinimalUITests.swift
//  MinimalUITests
//
//  Created by Ashton Meuser on 2026-10-29.
//

import XCTest

final class MinimalUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRepeatedCompactReturnHome() {
        let app = XCUIApplication()
        app.launch()

        let sidebarPath = app.staticTexts["sidebarFullPath"]
        let detailPath = app.staticTexts["detailFullPath"]

        func assertVisibleTitle(_ identifier: String, _ label: String) {
            let title = app.staticTexts
                .matching(identifier: identifier)
                .matching(NSPredicate(format: "label == %@", label))
                .firstMatch
            XCTAssertTrue(title.waitForExistence(timeout: 5))
            XCTAssertTrue(title.isHittable)
        }

        func pathText(_ element: XCUIElement) -> String {
            element.label.filter { !$0.isWhitespace }
        }

        assertVisibleTitle("sidebarTitle", "Sidebar 0")
        XCTAssertEqual(pathText(sidebarPath), "|")

        // Exercise both the NavigationLink and programmatic sidebar push.
        for pushSidebar in ["Navigate to Sidebar 1", "Go to Sidebar 1"] {
            app.buttons[pushSidebar].tap()
            assertVisibleTitle("sidebarTitle", "Sidebar 1")
            XCTAssertEqual(pathText(sidebarPath), "1|")

            app.buttons["Go to Detail 1"].tap()
            assertVisibleTitle("detailTitle", "Detail 1")
            XCTAssertEqual(pathText(detailPath), "1|1")

            app.buttons["Go to Root Sidebar"].tap()
            assertVisibleTitle("sidebarTitle", "Sidebar 0")
            XCTAssertEqual(pathText(sidebarPath), "|")
        }
    }
}

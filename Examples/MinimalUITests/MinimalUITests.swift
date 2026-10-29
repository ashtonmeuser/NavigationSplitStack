//
//  MinimalUITests.swift
//  MinimalUITests
//
//  Created by Ashton Meuser on 2026-10-29.
//

import XCTest
#if os(iOS)
import UIKit
#endif

final class MinimalUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRepeatedCompactReturnHome() throws {
        try requirePhone()
        let app = launchApp()
        assertSidebar(0, path: "|", in: app)

        for push in ["Navigate to Sidebar 1", "sidebarGoToNextSidebar"] {
            app.buttons[push].tap()
            assertSidebar(1, path: "1|", in: app)
            app.buttons["sidebarGoToDetail"].tap()
            assertDetail(1, path: "1|1", in: app)
            app.buttons["detailGoToRootSidebar"].tap()
            assertSidebar(0, path: "|", in: app)
        }
    }

    @MainActor
    func testCompactDepthAndPopping() throws {
        try requirePhone()
        let app = launchApp()
        app.buttons["sidebarGoToNextSidebar"].tap()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["Navigate to Sidebar 2"].tap()
        assertSidebar(2, path: "1→2|", in: app)
        app.buttons["Previous Sidebar"].tap()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["sidebarGoToNextSidebar"].tap()
        assertSidebar(2, path: "1→2|", in: app)
        app.buttons["sidebarGoToNextSidebar"].tap()
        assertSidebar(3, path: "1→2→3|", in: app)
        app.buttons["sidebarGoToRootSidebar"].tap()
        assertSidebar(0, path: "|", in: app)

        app.buttons["sidebarGoToDetail"].tap()
        assertDetail(1, path: "|1", in: app)
        app.buttons["Navigate to Detail 2"].tap()
        assertDetail(2, path: "|1→2", in: app)
        app.buttons["detailGoToNextDetail"].tap()
        assertDetail(3, path: "|1→2→3", in: app)
        app.buttons["Root Detail"].tap()
        assertDetail(1, path: "|1", in: app)
        app.buttons["detailGoToNextDetail"].tap()
        assertDetail(2, path: "|1→2", in: app)
        app.buttons["Previous Detail"].tap()
        assertDetail(1, path: "|1", in: app)
        app.buttons["Clear Detail"].tap()
        assertSidebar(0, path: "|", in: app)
    }

    @MainActor
    func testCompactColumnChangesAndRootReplacement() throws {
        try requirePhone()
        let app = launchApp()
        app.buttons["sidebarHideSidebar"].tap()
        assertSidebar(0, path: "|", in: app)
        app.buttons["sidebarGoToNextSidebar"].tap()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["sidebarGoToDetail"].tap()
        assertDetail(1, path: "1|1", in: app)
        app.buttons["detailShowSidebar"].tap()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["sidebarGoToDetail"].tap()
        assertDetail(1, path: "1|1", in: app)
        app.buttons["Show Current Sidebar"].tap()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["sidebarGoToDetail"].tap()
        assertDetail(1, path: "1|1", in: app)
        app.buttons["detailGoToNextSidebar"].tap()
        assertSidebar(2, path: "1→2|", in: app)
        app.buttons["sidebarGoToDetail"].tap()
        assertDetail(1, path: "1→2|1", in: app)
        app.buttons["Replace Detail Root with Detail 2"].tap()
        assertDetail(2, path: "1→2|2", in: app)
        app.buttons["Replace Detail Root with Detail 1"].tap()
        assertDetail(1, path: "1→2|1", in: app)
        app.buttons["detailGoToRootSidebar"].tap()
        assertSidebar(0, path: "|", in: app)
    }

    @MainActor
    func testWideEmptyDetailCanHideSidebar() throws {
        try requirePad()
        let app = launchApp()
        assertSidebar(0, path: "|", in: app)
        XCTAssertTrue(app.staticTexts["Make a selection"].waitForExistence(timeout: 5))
        app.buttons["sidebarHideSidebar"].tap()
        XCTAssertTrue(app.staticTexts["Make a selection"].isHittable)
        XCTAssertFalse(app.staticTexts["sidebarTitle"].isHittable)
    }

    @MainActor
    func testWideShowHideAndClearDetail() throws {
        try requirePad()
        let app = launchApp()
        app.buttons["sidebarGoToNextSidebar"].tap()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["sidebarGoToDetail"].tap()
        assertSidebar(1, path: "1|1", in: app)
        assertDetail(1, path: "1|1", in: app)
        app.buttons["sidebarHideSidebar"].tap()
        assertDetail(1, path: "1|1", in: app)
        XCTAssertFalse(app.staticTexts["sidebarTitle"].isHittable)
        app.buttons["detailShowSidebar"].tap()
        assertSidebar(1, path: "1|1", in: app)
        assertDetail(1, path: "1|1", in: app)
        app.buttons["sidebarHideSidebar"].tap()
        assertDetail(1, path: "1|1", in: app)
        app.buttons["Show Current Sidebar"].tap()
        assertSidebar(1, path: "1|1", in: app)
        assertDetail(1, path: "1|1", in: app)
        app.buttons["Clear Detail"].tap()
        assertSidebar(1, path: "1|", in: app)
        XCTAssertTrue(app.staticTexts["Make a selection"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testWidePathsAndDetailRootReplacement() throws {
        try requirePad()
        let app = launchApp()
        app.buttons["sidebarGoToNextSidebar"].tap()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["sidebarGoToDetail"].tap()
        assertDetail(1, path: "1|1", in: app)
        app.buttons["Replace Detail Root with Detail 2"].tap()
        assertDetail(2, path: "1|2", in: app)
        app.buttons["sidebarGoToDetail"].tap()
        assertDetail(1, path: "1|1", in: app)
        app.buttons["Navigate to Detail 2"].tap()
        assertDetail(2, path: "1|1→2", in: app)
        app.buttons["detailGoToNextDetail"].tap()
        assertDetail(3, path: "1|1→2→3", in: app)
        app.buttons["Previous Detail"].tap()
        assertDetail(2, path: "1|1→2", in: app)
        app.buttons["detailGoToNextSidebar"].tap()
        assertSidebar(2, path: "1→2|1→2", in: app)
        assertDetail(2, path: "1→2|1→2", in: app)
        app.buttons["Previous Sidebar"].tap()
        assertSidebar(1, path: "1|1→2", in: app)
        assertDetail(2, path: "1|1→2", in: app)
        app.buttons["detailGoToRootSidebar"].tap()
        assertSidebar(0, path: "|1→2", in: app)
        assertDetail(2, path: "|1→2", in: app)
    }

    @MainActor
    func testNativeWideSidebarToggle() throws {
        try requirePad()
        let app = launchApp()
        assertSidebar(0, path: "|", in: app)

        let nativeHide = app.buttons["Hide Sidebar"]
        XCTAssertTrue(nativeHide.waitForExistence(timeout: 5))
        nativeHide.tap()
        XCTAssertFalse(app.staticTexts["sidebarTitle"].isHittable)
        XCTAssertTrue(app.staticTexts["Make a selection"].isHittable)

        let nativeShow = app.buttons["Show Sidebar"]
        XCTAssertTrue(nativeShow.waitForExistence(timeout: 5))
        nativeShow.tap()
        assertSidebar(0, path: "|", in: app)
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    @MainActor
    private func assertSidebar(_ level: Int, path: String, in app: XCUIApplication) {
        assertVisibleTitle("sidebarTitle", label: "Sidebar \(level)", in: app)
        XCTAssertEqual(pathText("sidebarFullPath", in: app), path)
    }

    @MainActor
    private func assertDetail(_ level: Int, path: String, in app: XCUIApplication) {
        assertVisibleTitle("detailTitle", label: "Detail \(level)", in: app)
        XCTAssertEqual(pathText("detailFullPath", in: app), path)
    }

    @MainActor
    private func assertVisibleTitle(_ identifier: String, label: String, in app: XCUIApplication) {
        let title = app.staticTexts.matching(identifier: identifier)
            .matching(NSPredicate(format: "label == %@", label)).firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5), "Expected \(label)")
        XCTAssertTrue(title.isHittable, "Expected \(label) to be on screen")
    }

    @MainActor
    private func pathText(_ identifier: String, in app: XCUIApplication) -> String {
        app.staticTexts[identifier].label.filter { !$0.isWhitespace }
    }

    @MainActor
    private func requirePhone() throws {
        #if os(iOS)
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone, "Requires an iPhone")
        #else
        throw XCTSkip("Requires an iPhone")
        #endif
    }

    @MainActor
    private func requirePad() throws {
        #if os(iOS)
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "Requires an iPad")
        #else
        throw XCTSkip("Requires an iPad")
        #endif
    }
}

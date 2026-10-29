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

    // MARK: All Layouts

    @MainActor
    func testSidebarPushAndPop() {
        let app = launchApp()
        assertSidebar(0, path: "|", in: app)

        app.buttons["sidebarPushNextSidebar"].activate()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["sidebarPushNextSidebar"].activate()
        assertSidebar(2, path: "1→2|", in: app)
        app.buttons["Previous Sidebar"].activate()
        assertSidebar(1, path: "1|", in: app)
    }

    @MainActor
    func testDetailPushPopAndRootReplacement() {
        let app = launchApp()
        app.buttons["sidebarGoToDetail"].activate()
        assertDetail(1, path: "|1", in: app)

        app.buttons["detailPushNextDetail"].activate()
        assertDetail(2, path: "|1→2", in: app)
        app.buttons["Previous Detail"].activate()
        assertDetail(1, path: "|1", in: app)
        app.buttons["Replace Detail Root with Detail 2"].activate()
        assertDetail(2, path: "|2", in: app)
        app.buttons["Clear Detail"].activate()
        assertSidebar(0, path: "|", in: app)
    }

    // MARK: Compact Layout

    @MainActor
    func testRepeatedCompactReturnHome() throws {
        try requirePhone()
        let app = launchApp()
        assertSidebar(0, path: "|", in: app)

        for push in ["Navigate to Sidebar 1", "sidebarPushNextSidebar"] {
            app.buttons[push].activate()
            assertSidebar(1, path: "1|", in: app)
            app.buttons["sidebarGoToDetail"].activate()
            assertDetail(1, path: "1|1", in: app)
            app.buttons["detailGoToRootSidebar"].activate()
            assertSidebar(0, path: "|", in: app)
        }
    }

    @MainActor
    func testCompactDepthAndPopping() throws {
        try requirePhone()
        let app = launchApp()
        app.buttons["sidebarPushNextSidebar"].activate()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["Navigate to Sidebar 2"].activate()
        assertSidebar(2, path: "1→2|", in: app)
        app.buttons["Previous Sidebar"].activate()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["sidebarPushNextSidebar"].activate()
        assertSidebar(2, path: "1→2|", in: app)
        app.buttons["sidebarPushNextSidebar"].activate()
        assertSidebar(3, path: "1→2→3|", in: app)
        app.buttons["sidebarGoToRootSidebar"].activate()
        assertSidebar(0, path: "|", in: app)

        app.buttons["sidebarGoToDetail"].activate()
        assertDetail(1, path: "|1", in: app)
        app.buttons["Navigate to Detail 2"].activate()
        assertDetail(2, path: "|1→2", in: app)
        app.buttons["detailPushNextDetail"].activate()
        assertDetail(3, path: "|1→2→3", in: app)
        app.buttons["Root Detail"].activate()
        assertDetail(1, path: "|1", in: app)
        app.buttons["detailPushNextDetail"].activate()
        assertDetail(2, path: "|1→2", in: app)
        app.buttons["Previous Detail"].activate()
        assertDetail(1, path: "|1", in: app)
        app.buttons["Clear Detail"].activate()
        assertSidebar(0, path: "|", in: app)
    }

    @MainActor
    func testCompactColumnChangesAndRootReplacement() throws {
        try requirePhone()
        let app = launchApp()
        app.buttons["sidebarHideSidebar"].activate()
        assertSidebar(0, path: "|", in: app)
        app.buttons["sidebarPushNextSidebar"].activate()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["sidebarGoToDetail"].activate()
        assertDetail(1, path: "1|1", in: app)
        app.buttons["detailShowSidebar"].activate()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["sidebarGoToDetail"].activate()
        assertDetail(1, path: "1|1", in: app)
        app.buttons["Show Current Sidebar"].activate()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["sidebarGoToDetail"].activate()
        assertDetail(1, path: "1|1", in: app)
        app.buttons["detailPushNextSidebar"].activate()
        assertSidebar(2, path: "1→2|", in: app)
        app.buttons["sidebarGoToDetail"].activate()
        assertDetail(1, path: "1→2|1", in: app)
        app.buttons["Replace Detail Root with Detail 2"].activate()
        assertDetail(2, path: "1→2|2", in: app)
        app.buttons["Replace Detail Root with Detail 1"].activate()
        assertDetail(1, path: "1→2|1", in: app)
        app.buttons["detailGoToRootSidebar"].activate()
        assertSidebar(0, path: "|", in: app)
    }

    // MARK: Wide Layout

    @MainActor
    func testWideEmptyDetailCanHideSidebar() throws {
        try requireWideLayout()
        let app = launchApp()
        assertSidebar(0, path: "|", in: app)
        XCTAssertTrue(
            app.staticTexts["Make a selection"].waitForExistence(timeout: 5)
        )
        app.buttons["sidebarHideSidebar"].activate()
        XCTAssertTrue(app.staticTexts["Make a selection"].isHittable)
        XCTAssertFalse(app.staticTexts["sidebarTitle"].isHittable)
    }

    @MainActor
    func testWideShowHideAndClearDetail() throws {
        try requireWideLayout()
        let app = launchApp()
        app.buttons["sidebarPushNextSidebar"].activate()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["sidebarGoToDetail"].activate()
        assertSidebar(1, path: "1|1", in: app)
        assertDetail(1, path: "1|1", in: app)
        app.buttons["sidebarHideSidebar"].activate()
        assertDetail(1, path: "1|1", in: app)
        XCTAssertFalse(app.staticTexts["sidebarTitle"].isHittable)
        app.buttons["detailShowSidebar"].activate()
        assertSidebar(1, path: "1|1", in: app)
        assertDetail(1, path: "1|1", in: app)
        app.buttons["sidebarHideSidebar"].activate()
        assertDetail(1, path: "1|1", in: app)
        app.buttons["Show Current Sidebar"].activate()
        assertSidebar(1, path: "1|1", in: app)
        assertDetail(1, path: "1|1", in: app)
        app.buttons["Clear Detail"].activate()
        assertSidebar(1, path: "1|", in: app)
        XCTAssertTrue(
            app.staticTexts["Make a selection"].waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testWidePathsAndDetailRootReplacement() throws {
        try requireWideLayout()
        let app = launchApp()
        app.buttons["sidebarPushNextSidebar"].activate()
        assertSidebar(1, path: "1|", in: app)
        app.buttons["sidebarGoToDetail"].activate()
        assertDetail(1, path: "1|1", in: app)
        app.buttons["Replace Detail Root with Detail 2"].activate()
        assertDetail(2, path: "1|2", in: app)
        app.buttons["sidebarGoToDetail"].activate()
        assertDetail(1, path: "1|1", in: app)
        app.buttons["Navigate to Detail 2"].activate()
        assertDetail(2, path: "1|1→2", in: app)
        app.buttons["detailPushNextDetail"].activate()
        assertDetail(3, path: "1|1→2→3", in: app)
        app.buttons["Previous Detail"].activate()
        assertDetail(2, path: "1|1→2", in: app)
        app.buttons["detailPushNextSidebar"].activate()
        assertSidebar(2, path: "1→2|1→2", in: app)
        assertDetail(2, path: "1→2|1→2", in: app)
        app.buttons["Previous Sidebar"].activate()
        assertSidebar(1, path: "1|1→2", in: app)
        assertDetail(2, path: "1|1→2", in: app)
        app.buttons["detailGoToRootSidebar"].activate()
        assertSidebar(0, path: "|1→2", in: app)
        assertDetail(2, path: "|1→2", in: app)
        app.buttons["sidebarPushNextDetail"].activate()
        assertSidebar(0, path: "|1→2→3", in: app)
        assertDetail(3, path: "|1→2→3", in: app)
    }

    @MainActor
    func testNativeWideSidebarToggle() throws {
        try requireWideLayout()
        let app = launchApp()
        assertSidebar(0, path: "|", in: app)

        let nativeHide = app.buttons["Hide Sidebar"]
        XCTAssertTrue(nativeHide.waitForExistence(timeout: 5))
        nativeHide.activate()
        let sidebarTitle = app.staticTexts["sidebarTitle"]
        XCTAssertTrue(
            sidebarTitle.wait(for: \.isHittable, toEqual: false, timeout: 5),
            "Sidebar did not finish hiding"
        )
        XCTAssertTrue(app.staticTexts["Make a selection"].isHittable)

        let nativeShow = app.buttons["Show Sidebar"]
        XCTAssertTrue(nativeShow.waitForExistence(timeout: 5))
        nativeShow.activate()
        XCTAssertTrue(
            sidebarTitle.wait(for: \.isHittable, toEqual: true, timeout: 5),
            "Sidebar did not finish showing"
        )
        assertSidebar(0, path: "|", in: app)
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    @MainActor
    private func assertSidebar(
        _ level: Int,
        path: String,
        in app: XCUIApplication
    ) {
        assertVisibleTitle("sidebarTitle", label: "Sidebar \(level)", in: app)
        XCTAssertEqual(pathText("sidebarFullPath", in: app), path)
    }

    @MainActor
    private func assertDetail(
        _ level: Int,
        path: String,
        in app: XCUIApplication
    ) {
        assertVisibleTitle("detailTitle", label: "Detail \(level)", in: app)
        XCTAssertEqual(pathText("detailFullPath", in: app), path)
    }

    @MainActor
    private func assertVisibleTitle(
        _ identifier: String,
        label: String,
        in app: XCUIApplication
    ) {
        let title = app.staticTexts[identifier]
        XCTAssertTrue(
            title.waitForExistence(timeout: 5),
            "Expected element \(identifier)"
        )
        XCTAssertEqual(
            accessibilityText(of: title),
            label,
            "Unexpected title for \(identifier)"
        )
        XCTAssertTrue(title.isHittable, "Expected \(label) to be on screen")
    }

    @MainActor
    private func pathText(_ identifier: String, in app: XCUIApplication)
        -> String
    {
        accessibilityText(of: app.staticTexts[identifier]).filter {
            !$0.isWhitespace
        }
    }

    @MainActor
    private func accessibilityText(of element: XCUIElement) -> String {
        if !element.label.isEmpty { return element.label }
        if let value = element.value as? String, !value.isEmpty { return value }
        return element.title
    }

    @MainActor
    private func requirePhone() throws {
        #if os(iOS)
            try XCTSkipUnless(
                UIDevice.current.userInterfaceIdiom == .phone,
                "Requires an iPhone"
            )
        #else
            throw XCTSkip("Requires an iPhone")
        #endif
    }

    @MainActor
    private func requireWideLayout() throws {
        #if os(iOS)
            try XCTSkipUnless(
                UIDevice.current.userInterfaceIdiom == .pad,
                "Requires iPad or macOS"
            )
        #elseif os(macOS)
            return
        #else
            throw XCTSkip("Requires iPad or macOS")
        #endif
    }
}

extension XCUIElement {
    @MainActor
    fileprivate func activate() {
        #if os(macOS)
            click()
        #else
            tap()
        #endif
    }
}

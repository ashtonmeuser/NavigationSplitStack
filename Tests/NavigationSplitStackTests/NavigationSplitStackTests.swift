import SwiftUI
import Testing
@testable import NavigationSplitStack

private typealias Router = NavigationSplitStackRouter<Int, Int>

@Test
@MainActor
func compactColumnTransitions() {
    let router = Router()
    router.horizontalSizeClass = .compact

    router.hideSidebar()
    #expect(router.columnVisibility == .doubleColumn)
    #expect(router.preferredCompactColumn == .sidebar)

    router.detail.append(10)
    #expect(router.detail == [10])
    #expect(router.preferredCompactColumn == .detail)

    router.hideSidebar()
    #expect(router.columnVisibility == .detailOnly)
    router.showSidebar()
    #expect(router.detail.isEmpty)
    #expect(router.columnVisibility == .doubleColumn)
    #expect(router.preferredCompactColumn == .sidebar)
}

@Test
@MainActor
func wideColumnTransitionsPreservePaths() {
    let router = Router()
    router.horizontalSizeClass = .regular
    router.sidebar = [1]
    router.detail = [10, 11]

    router.hideSidebar()
    #expect(router.columnVisibility == .detailOnly)
    router.showSidebar()
    #expect(router.columnVisibility == .doubleColumn)
    #expect(router.sidebar == [1])
    #expect(router.detail == [10, 11])

    router.detail.removeAll()
    router.hideSidebar()
    #expect(router.columnVisibility == .detailOnly)
    #expect(router.detail.isEmpty)
}

@Test
@MainActor
func assigningTheSameSidebarPathShowsItAgain() {
    let wideRouter = Router()
    wideRouter.horizontalSizeClass = .regular
    wideRouter.sidebar = [1]
    wideRouter.detail = [10]
    wideRouter.hideSidebar()

    wideRouter.sidebar = wideRouter.sidebar
    #expect(wideRouter.columnVisibility == .doubleColumn)
    #expect(wideRouter.sidebar == [1])
    #expect(wideRouter.detail == [10])

    let compactRouter = Router()
    compactRouter.horizontalSizeClass = .compact
    compactRouter.sidebar = [1]
    compactRouter.detail = [10]

    compactRouter.sidebar = compactRouter.sidebar
    #expect(compactRouter.sidebar == [1])
    #expect(compactRouter.detail.isEmpty)
    #expect(compactRouter.preferredCompactColumn == .sidebar)
}

@Test
@MainActor
func compactSidebarMutationsClearDetail() {
    let router = Router()
    router.horizontalSizeClass = .compact
    router.sidebar = [1]

    router.detail = [10]
    router.sidebar.append(2)
    #expect(router.sidebar == [1, 2])
    #expect(router.detail.isEmpty)
    #expect(router.preferredCompactColumn == .sidebar)

    router.detail = [11]
    router.sidebar.removeLast()
    #expect(router.sidebar == [1])
    #expect(router.detail.isEmpty)
    #expect(router.preferredCompactColumn == .sidebar)

    router.detail = [12]
    router.sidebar.removeAll()
    #expect(router.sidebar.isEmpty)
    #expect(router.detail.isEmpty)
    #expect(router.columnVisibility == .doubleColumn)
}

@Test
@MainActor
func wideSidebarMutationsShowSidebarAndPreserveDetail() {
    let router = Router()
    router.horizontalSizeClass = .regular
    router.sidebar = [1]
    router.detail = [10, 11]

    router.hideSidebar()
    router.sidebar.append(2)
    #expect(router.sidebar == [1, 2])
    #expect(router.detail == [10, 11])
    #expect(router.columnVisibility == .doubleColumn)

    router.hideSidebar()
    router.sidebar.removeLast()
    #expect(router.sidebar == [1])
    #expect(router.detail == [10, 11])
    #expect(router.columnVisibility == .doubleColumn)

    router.hideSidebar()
    router.sidebar.removeAll()
    #expect(router.sidebar.isEmpty)
    #expect(router.detail == [10, 11])
    #expect(router.columnVisibility == .doubleColumn)
}

@Test
@MainActor
func wideEmptyDetailCanHideAndShowSidebar() {
    let router = Router()
    router.horizontalSizeClass = .regular
    router.sidebar = [1]

    router.hideSidebar()
    #expect(router.columnVisibility == .detailOnly)
    router.showSidebar()
    #expect(router.columnVisibility == .doubleColumn)
    #expect(router.sidebar == [1])
    #expect(router.detail.isEmpty)
}

@Test
@MainActor
func nestedDetailPathPreservesItsRoot() {
    let router = Router()
    router.detail = [1, 2, 3]
    #expect(router.detailRest == [2, 3])

    router.detailRest = [4, 5]
    #expect(router.detail == [1, 4, 5])
    router.detailRest = []
    #expect(router.detail == [1])

    router.detail.removeAll()
    router.detailRest = [99]
    #expect(router.detail.isEmpty)
}

@Test
@MainActor
func systemReturnToSidebarClearsOnlyCompactDetail() {
    let compactRouter = Router()
    compactRouter.horizontalSizeClass = .compact
    compactRouter.detail = [1, 2]
    compactRouter.preferredCompactColumn = .sidebar
    #expect(compactRouter.detail.isEmpty)

    let wideRouter = Router()
    wideRouter.horizontalSizeClass = .regular
    wideRouter.detail = [1, 2]
    wideRouter.preferredCompactColumn = .sidebar
    #expect(wideRouter.detail == [1, 2])
}

@Test
@MainActor
func changingNonemptyDetailPathKeepsPresentation() {
    let router = Router()
    router.horizontalSizeClass = .regular
    router.detail = [1]
    router.hideSidebar()

    router.detail.append(2)
    #expect(router.detail == [1, 2])
    #expect(router.columnVisibility == .detailOnly)
    router.detail = [3]
    #expect(router.detail == [3])
    #expect(router.columnVisibility == .detailOnly)

    router.detail.removeAll()
    #expect(router.columnVisibility == .doubleColumn)
    #expect(router.preferredCompactColumn == .sidebar)
}

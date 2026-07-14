import XCTest

@MainActor
final class ResourceScreensUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCalendarsLoadsBrowsableHierarchy() {
        launchApp()
        openExploreTool("explore.resource.calendars")

        XCTAssertTrue(app.navigationBars["Academic Calendars"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Browse"].waitForExistence(timeout: 35))
        let currentYear = app.staticTexts["2026-2027"]
        if currentYear.waitForExistence(timeout: 5) {
            currentYear.tap()
            XCTAssertTrue(app.navigationBars["2026-2027"].waitForExistence(timeout: 8))
            XCTAssertTrue(app.staticTexts["B.Tech"].waitForExistence(timeout: 8))
        }
        attach("academic-calendars")
    }

    func testSyllabusLoadsBrowsableHierarchy() {
        launchApp()
        openExploreTool("explore.resource.syllabus")

        XCTAssertTrue(app.navigationBars["Syllabus"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Browse"].waitForExistence(timeout: 35))
        let btech = app.staticTexts["B.Tech"]
        XCTAssertTrue(btech.waitForExistence(timeout: 8))
        btech.tap()
        XCTAssertTrue(app.navigationBars["B.Tech"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["R22"].waitForExistence(timeout: 8))
        attach("syllabus-browser")
    }

    func testChannelsShowsAllCommunities() {
        launchApp()
        openExploreTool("explore.channels")

        XCTAssertTrue(app.navigationBars["Channels"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["JNTUH Connect"].exists)
        XCTAssertTrue(app.staticTexts["WhatsApp group"].exists)
        attach("channels")
    }

    func testHelpCenterExpandsAnswer() {
        launchApp()
        openExploreTool("explore.help")

        XCTAssertTrue(app.navigationBars["Help Center"].waitForExistence(timeout: 10))
        let question = app.buttons["How do I check my complete result?"]
        XCTAssertTrue(question.waitForExistence(timeout: 5))
        question.tap()
        let answer = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Enter your 10-character hall ticket number on Home.")
        ).firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 3))
        attach("help-center")
    }

    func testHomeSearchOpensUnifiedFourSectionResult() {
        launchApp()
        selectRootTab("Home", marker: app.textFields["Hall ticket number"])
        let field = app.textFields["Hall ticket number"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("18E51A0479")
        app.buttons["View result"].tap()

        XCTAssertTrue(app.navigationBars["Student Result"].waitForExistence(timeout: 10))
        for title in ["All Results", "Academic", "Backlogs", "Credits"] {
            XCTAssertTrue(app.buttons[title].waitForExistence(timeout: 35), "Missing result section: \(title)")
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            XCTAssertFalse(app.buttons["student.section.allResults.sidebar"].exists)
        }
        app.buttons["All Results"].tap()
        XCTAssertTrue(app.staticTexts["Every published attempt, subject mark and official JNTUH result link."].waitForExistence(timeout: 35))
        attach("home-unified-result")
    }

    func testHomeKeyboardDismissesOnOutsideTapAndScroll() {
        launchApp()
        let field = app.textFields["Hall ticket number"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))

        field.tap()
        field.typeText("18E")
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
        app.staticTexts["JNTUH Connect"].firstMatch.tap()
        XCTAssertTrue(waitUntilKeyboardIsDismissed())

        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
        app.swipeUp()
        XCTAssertTrue(waitUntilKeyboardIsDismissed())
    }

    func testRootTabsKeepTopChromeReadableAfterScrolling() {
        captureRootTabTopGlass(appearance: "light")
    }

    func testRootTabsUseNativeTopGlassInDarkAppearance() {
        captureRootTabTopGlass(appearance: "dark")
    }

    func testPrivacyDisclosureIsAccessibleFromSettings() {
        launchApp()
        selectRootTab("Settings", marker: app.staticTexts["Settings"].firstMatch)

        let privacy = app.buttons["profile.privacy"]
        XCTAssertTrue(privacy.waitForExistence(timeout: 5))
        privacy.tap()

        XCTAssertTrue(app.navigationBars["Privacy & Data"].waitForExistence(timeout: 5))
        assertPrivacySectionIsReachable("privacy.localData")
        assertPrivacySectionIsReachable("privacy.sentData")
        assertPrivacySectionIsReachable("privacy.noUploads")
        attach("privacy-and-data")
    }

    private func assertPrivacySectionIsReachable(_ identifier: String) {
        let section = app.descendants(matching: .any)[identifier]
        for _ in 0..<6 where !section.exists { app.swipeUp() }
        XCTAssertTrue(section.waitForExistence(timeout: 3), "Expected to reach privacy section \(identifier)")
    }

    private func captureRootTabTopGlass(appearance: String) {
        launchApp(arguments: ["-appearance", appearance])

        XCTAssertTrue(app.staticTexts["Quick tools"].waitForExistence(timeout: 8))
        attach("home-\(appearance)-initial")
        app.swipeUp()
        app.swipeUp()
        attach("home-\(appearance)-scrolled-top-glass")

        selectRootTab("Explore", marker: app.staticTexts["Explore"].firstMatch)
        attach("explore-\(appearance)-initial")
        app.swipeUp()
        app.swipeUp()
        attach("explore-\(appearance)-scrolled-top-glass")

        selectRootTab("Settings", marker: app.staticTexts["Settings"].firstMatch)
        attach("settings-\(appearance)-initial")
        app.swipeUp()
        app.swipeUp()
        attach("settings-\(appearance)-scrolled-top-glass")
    }

    private func selectRootTab(_ label: String, marker: XCUIElement) {
        let button = app.buttons[label].firstMatch
        let sidebarCell = app.cells.containing(.staticText, identifier: label).firstMatch
        let tab = button.waitForExistence(timeout: 1) ? button : sidebarCell
        XCTAssertTrue(tab.waitForExistence(timeout: 3))
        tab.tap()

        // Appearance changes can briefly overlap the native tab transition in UI tests.
        if !marker.waitForExistence(timeout: 3) {
            tab.tap()
        }
        XCTAssertTrue(marker.waitForExistence(timeout: 8))
    }

    func testIPadPortraitRootLayoutsAdapt() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("iPad layout verification")
        }
        verifyIPadRootLayouts(orientation: .portrait, attachmentSuffix: "portrait")
    }

    func testIPadLandscapeRootLayoutsAdapt() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("iPad layout verification")
        }
        verifyIPadRootLayouts(orientation: .landscapeLeft, attachmentSuffix: "landscape")
    }

    func testIPadPortraitStudentResultAdapts() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("iPad result layout verification")
        }
        verifyIPadStudentResult(
            orientation: .portrait,
            attachmentSuffix: "portrait",
            expectsSidebar: false
        )
    }

    func testIPadLandscapeStudentResultAdapts() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("iPad result layout verification")
        }
        verifyIPadStudentResult(
            orientation: .landscapeLeft,
            attachmentSuffix: "landscape",
            expectsSidebar: true
        )
    }

    func testIPhoneKeepsCompactRootLayouts() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("iPhone compact-layout verification")
        }

        launchApp()
        selectRootTab("Home", marker: app.textFields["Hall ticket number"])

        let quickTools = ["credits", "classResults", "calendars", "syllabus"].map {
            app.buttons["home.quick.\($0)"]
        }
        for tool in quickTools {
            if !tool.waitForExistence(timeout: 2) { app.swipeUp() }
            XCTAssertTrue(tool.waitForExistence(timeout: 5))
        }
        XCTAssertEqual(quickTools[0].frame.minY, quickTools[1].frame.minY, accuracy: 3)
        XCTAssertEqual(quickTools[0].frame.minX, quickTools[2].frame.minX, accuracy: 3)
        XCTAssertGreaterThan(quickTools[2].frame.minY, quickTools[0].frame.minY)

        selectRootTab("Settings", marker: app.staticTexts["Settings"].firstMatch)
        XCTAssertFalse(app.segmentedControls.firstMatch.exists)
        XCTAssertTrue(app.buttons["profile.privacy"].waitForExistence(timeout: 5))
    }

    private func verifyIPadRootLayouts(
        orientation: UIDeviceOrientation,
        attachmentSuffix: String
    ) {
        launchApp(orientation: orientation)

        selectRootTab("Home", marker: app.textFields["Hall ticket number"])

        let quickTools = ["credits", "classResults", "calendars", "syllabus"].map {
            app.buttons["home.quick.\($0)"]
        }
        for tool in quickTools {
            XCTAssertTrue(tool.waitForExistence(timeout: 5))
        }
        let toolRowY = quickTools[0].frame.minY
        for tool in quickTools.dropFirst() {
            XCTAssertEqual(tool.frame.minY, toolRowY, accuracy: 3, "iPad quick tools should share one row")
        }
        attach("ipad-home-\(attachmentSuffix)")

        selectRootTab("Explore", marker: app.staticTexts["Explore"].firstMatch)
        let resultTools = ["academic", "allResults", "backlogs"].map {
            app.buttons["explore.\($0)"]
        }
        for tool in resultTools {
            XCTAssertTrue(tool.waitForExistence(timeout: 5))
        }
        XCTAssertLessThan(resultTools[0].frame.minX, resultTools[1].frame.minX)
        if resultTools[2].frame.minX > resultTools[1].frame.minX {
            XCTAssertLessThan(resultTools[1].frame.minX, resultTools[2].frame.minX)
        } else {
            XCTAssertEqual(resultTools[0].frame.minX, resultTools[2].frame.minX, accuracy: 3)
            XCTAssertGreaterThan(resultTools[2].frame.minY, resultTools[0].frame.minY)
        }
        attach("ipad-explore-\(attachmentSuffix)")

        selectRootTab("Settings", marker: app.staticTexts["Settings"].firstMatch)
        XCTAssertTrue(app.segmentedControls.firstMatch.waitForExistence(timeout: 5))
        attach("ipad-settings-\(attachmentSuffix)")

        let privacy = app.buttons["profile.privacy"]
        let help = app.buttons["profile.help"]
        XCTAssertTrue(privacy.waitForExistence(timeout: 5))
        XCTAssertTrue(help.waitForExistence(timeout: 5))
        XCTAssertTrue(privacy.isHittable)
        XCTAssertTrue(help.isHittable)
    }

    private func verifyIPadStudentResult(
        orientation: UIDeviceOrientation,
        attachmentSuffix: String,
        expectsSidebar: Bool
    ) {
        launchApp(orientation: orientation)
        selectRootTab("Home", marker: app.textFields["Hall ticket number"])

        let field = app.textFields["Hall ticket number"]
        field.tap()
        field.typeText("18E51A0479")
        app.buttons["View result"].tap()

        XCTAssertTrue(app.navigationBars["Student Result"].waitForExistence(timeout: 10))
        let sections = [
            (title: "All Results", rawValue: "allResults"),
            (title: "Academic", rawValue: "academic"),
            (title: "Backlogs", rawValue: "backlogs"),
            (title: "Credits", rawValue: "credits")
        ]
        for section in sections {
            let button = expectsSidebar
                ? app.buttons["student.section.\(section.rawValue).sidebar"]
                : app.buttons[section.title]
            XCTAssertTrue(button.waitForExistence(timeout: 35), "Missing result section: \(section.title)")
        }

        let allResultsSidebarButton = app.buttons["student.section.allResults.sidebar"]
        if expectsSidebar {
            XCTAssertTrue(allResultsSidebarButton.waitForExistence(timeout: 5))
        } else {
            XCTAssertFalse(allResultsSidebarButton.exists)
        }
        attach("ipad-student-academic-\(attachmentSuffix)")

        let allResultsButton = expectsSidebar ? allResultsSidebarButton : app.buttons["All Results"].firstMatch
        allResultsButton.tap()
        XCTAssertTrue(
            app.staticTexts["Every published attempt, subject mark and official JNTUH result link."]
                .waitForExistence(timeout: 35)
        )
        waitForUIToSettle()
        attach("ipad-student-all-results-\(attachmentSuffix)")
    }

    private func waitForUIToSettle() {
        let settled = expectation(description: "UI transition settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            settled.fulfill()
        }
        wait(for: [settled], timeout: 1)
    }

    private func launchApp(
        orientation: UIDeviceOrientation = .portrait,
        arguments: [String] = []
    ) {
        XCUIDevice.shared.orientation = orientation
        app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
    }

    private func openExploreTool(_ identifier: String) {
        app.buttons["Explore"].firstMatch.tap()
        let tool = app.buttons[identifier]
        for _ in 0..<8 {
            if tool.exists && tool.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(tool.waitForExistence(timeout: 5))
        XCTAssertTrue(tool.isHittable)
        tool.tap()
    }

    private func waitUntilKeyboardIsDismissed() -> Bool {
        let keyboard = app.keyboards.firstMatch
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: keyboard
        )
        return XCTWaiter.wait(for: [expectation], timeout: 3) == .completed
    }

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

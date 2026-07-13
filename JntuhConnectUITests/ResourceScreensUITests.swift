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
        let field = app.textFields["Hall ticket number"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("18E51A0479")
        app.buttons["View result"].tap()

        XCTAssertTrue(app.navigationBars["Student Result"].waitForExistence(timeout: 10))
        for title in ["All Results", "Academic", "Backlogs", "Credits"] {
            XCTAssertTrue(app.buttons[title].waitForExistence(timeout: 35), "Missing result section: \(title)")
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
        let tab = app.buttons[label].firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 3))
        tab.tap()

        // Appearance changes can briefly overlap the native tab transition in UI tests.
        if !marker.waitForExistence(timeout: 3) {
            app.buttons[label].firstMatch.tap()
        }
        XCTAssertTrue(marker.waitForExistence(timeout: 8))
    }

    func testIPadLandscapeHomeAdapts() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("iPad layout verification")
        }
        launchApp(orientation: .landscapeLeft)
        XCTAssertTrue(app.textFields["Hall ticket number"].waitForExistence(timeout: 8))
        attach("ipad-home-landscape")
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

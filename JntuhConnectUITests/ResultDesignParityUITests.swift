import XCTest

@MainActor
final class ResultDesignParityUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAcademicResultDesign() {
        launchApp()
        openResultTool("academic", roll: "18E51A0479")
        XCTAssertTrue(app.navigationBars["Student Result"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["POTHUGANTI THILAK REDDY"].waitForExistence(timeout: 45))
        attach("academic-result")
    }

    func testResultSectionPickerScrollsAway() {
        launchApp()
        openResultTool("academic", roll: "18E51A0479")
        XCTAssertTrue(app.buttons["Academic"].firstMatch.waitForExistence(timeout: 45))

        for _ in 0..<5 { app.swipeUp() }

        XCTAssertFalse(app.buttons["Academic"].firstMatch.isHittable)
        attach("academic-result-scrolled-no-floating-picker")
    }

    func testAllResultsDesign() {
        launchApp()
        openResultTool("allResults", roll: "18E51A0479")
        XCTAssertTrue(app.navigationBars["Student Result"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Semester 1-1"].waitForExistence(timeout: 45))
        attach("all-results")
    }

    func testBacklogResultDesign() {
        launchApp()
        openResultTool("backlogs", roll: "18E51A0578")
        XCTAssertTrue(app.navigationBars["Student Result"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["3 active backlogs"].waitForExistence(timeout: 45))
        attach("backlog-result")
    }

    func testCreditsCheckerDesign() {
        launchApp()
        openResultTool("credits", roll: "18E51A0578")
        XCTAssertTrue(app.navigationBars["Student Result"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Credit progress"].waitForExistence(timeout: 45))
        attach("credits-checker")
    }

    func testClassResultsDesign() {
        launchApp()
        openResultTool("classResults", roll: "18E51A0479")
        XCTAssertTrue(app.navigationBars["Class result"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Class ranking"].waitForExistence(timeout: 45))
        attach("class-results")

        let backlogsMode = app.buttons["Backlogs"]
        XCTAssertTrue(backlogsMode.waitForExistence(timeout: 5))
        backlogsMode.tap()
        XCTAssertTrue(app.staticTexts["Most backlogs first"].waitForExistence(timeout: 45))
        XCTAssertTrue(app.staticTexts["View an entire class"].exists)
        attach("class-backlogs")
    }

    func testAcademicResultDarkMode() {
        launchApp(arguments: ["-appearance", "dark"])
        openResultTool("academic", roll: "18E51A0479")
        XCTAssertTrue(app.staticTexts["POTHUGANTI THILAK REDDY"].waitForExistence(timeout: 45))
        attach("academic-result-dark")
    }

    func testAcademicResultAccessibilityXXXL() {
        launchApp(arguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        openResultTool("academic", roll: "18E51A0479")
        XCTAssertTrue(app.staticTexts["POTHUGANTI THILAK REDDY"].waitForExistence(timeout: 45))
        XCTAssertTrue(app.buttons["Academic"].exists)
        attach("academic-result-accessibility-xxxl")
    }

    private func openResultTool(_ id: String, roll: String) {
        app.buttons["Explore"].firstMatch.tap()
        let tool = app.buttons["explore.\(id)"]
        for _ in 0..<6 where !tool.isHittable { app.swipeUp() }
        XCTAssertTrue(tool.waitForExistence(timeout: 5))
        tool.tap()

        let field = app.textFields["result.primaryRoll"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText(roll)
        let submit = app.buttons["result.submit"]
        if !submit.isHittable { app.swipeUp() }
        submit.tap()
    }

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func launchApp(arguments: [String] = []) {
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
    }
}

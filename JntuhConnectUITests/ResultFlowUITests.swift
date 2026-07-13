import XCTest

@MainActor
final class ResultFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCreditsBottomSheetSubmitsAndLoadsLiveReport() throws {
        let app = XCUIApplication()
        app.launch()

        let credits = app.buttons["home.quick.credits"]
        if !credits.isHittable { app.swipeUp() }
        XCTAssertTrue(credits.waitForExistence(timeout: 5))
        credits.tap()

        let field = app.textFields["result.primaryRoll"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("18E51A0479")

        let submit = app.buttons["result.submit"]
        if submit.isHittable {
            submit.tap()
        } else {
            app.keyboards.buttons["go"].tap()
        }

        XCTAssertTrue(app.navigationBars["Student Result"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Credit progress"].waitForExistence(timeout: 45))
        XCTAssertFalse(app.tabBars.firstMatch.isHittable, "Pushed result screens must hide the persistent tab bar")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "credits-live-result"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testBrandedLoadingIndicatorPresentation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-test-hold-loading", "-appearance", "light"]
        app.launch()

        let credits = app.buttons["home.quick.credits"]
        if !credits.isHittable { app.swipeUp() }
        XCTAssertTrue(credits.waitForExistence(timeout: 5))
        credits.tap()

        let field = app.textFields["result.primaryRoll"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("18E51A0479")

        let submit = app.buttons["result.submit"]
        if submit.isHittable {
            submit.tap()
        } else {
            app.keyboards.buttons["go"].tap()
        }

        let loading = app.descendants(matching: .any)["app.loading"]
        XCTAssertTrue(loading.waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "branded-result-loading"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testContrastSheetProvidesTwoRollNumberFields() throws {
        let app = XCUIApplication()
        app.launch()

        let contrast = app.buttons["home.quick.contrast"]
        if !contrast.isHittable { app.swipeUp() }
        XCTAssertTrue(contrast.waitForExistence(timeout: 5))
        contrast.tap()

        XCTAssertTrue(app.textFields["result.primaryRoll"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["result.secondaryRoll"].exists)
        XCTAssertTrue(app.buttons["result.submit"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "result-contrast-sheet"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}

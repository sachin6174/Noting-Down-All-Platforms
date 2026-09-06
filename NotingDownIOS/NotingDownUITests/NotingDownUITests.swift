import XCTest

@MainActor
final class NotingDownUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-reset", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    }

    private func openNotes(_ title: String = "Notes") {
        let tab = app.tabBars.buttons[title]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()
        XCTAssertTrue(app.buttons["notes.add"].waitForExistence(timeout: 5))
    }

    private func createNote(title: String, body: String) {
        app.buttons["notes.add"].tap()
        let titleField = app.textFields["editor.title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText(title)
        let bodyField = app.textViews["editor.body"]
        bodyField.tap()
        bodyField.typeText(body)
        app.buttons["editor.save"].tap()
        XCTAssertTrue(app.staticTexts[title].firstMatch.waitForExistence(timeout: 5))
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCreateSearchEditPersistAndDelete() {
        app.launch()
        openNotes()
        createNote(title: "Offline test note", body: "A note that survives relaunch.")
        app.terminate()
        app.launchArguments.removeAll { $0 == "-ui-reset" }
        app.launch()
        openNotes()
        let search = app.textFields["notes.search"]
        search.tap()
        search.typeText("survives")
        let note = app.staticTexts["Offline test note"].firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()
        app.buttons["note.actions"].tap()
        app.buttons["Edit Note"].tap()
        let titleField = app.textFields["editor.title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText(" updated")
        app.buttons["editor.save"].tap()
        XCTAssertTrue(app.staticTexts["Offline test note updated"].waitForExistence(timeout: 5))
        app.buttons["note.actions"].tap()
        app.buttons["Delete Note"].tap()
        app.alerts.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["No notes yet"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        openNotes()
        XCTAssertTrue(app.staticTexts["No notes yet"].waitForExistence(timeout: 5))
    }

    func testBlankTitleCannotSaveAndCancelDoesNotCreate() {
        app.launch()
        openNotes()
        app.buttons["notes.add"].tap()
        XCTAssertFalse(app.buttons["editor.save"].isEnabled)
        app.textFields["editor.title"].tap()
        app.textFields["editor.title"].typeText("   ")
        XCTAssertFalse(app.buttons["editor.save"].isEnabled)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["No notes yet"].waitForExistence(timeout: 5))
    }

    func testSpanishAndAccessibilityTextSize() {
        app.launchArguments = ["-ui-testing", "-ui-reset", "-AppleLanguages", "(es)", "-AppleLocale", "es_ES", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        openNotes("Notas")
        XCTAssertTrue(app.staticTexts["Aún no hay notas"].waitForExistence(timeout: 5))
        app.buttons["notes.add"].tap()
        XCTAssertTrue(app.textFields["editor.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["editor.save"].label, "Guardar")
        XCTAssertTrue(app.buttons["editor.save"].isHittable)
        capture("Spanish-large-text-editor")
    }

    /// The CI recording script runs this method alone for a short real simulator demo.
    func testDemoWalkthrough() {
        app.launch()
        openNotes()
        createNote(title: "Weekend ideas", body: "Walk by the river. Bring a notebook.")
        capture("01-notes")
        let search = app.textFields["notes.search"]
        search.tap()
        search.typeText("river")
        XCTAssertTrue(app.staticTexts["Weekend ideas"].firstMatch.waitForExistence(timeout: 5))
        capture("02-search")
        app.staticTexts["Weekend ideas"].firstMatch.tap()
        capture("03-detail")
        app.buttons["note.actions"].tap()
        app.buttons["Edit Note"].tap()
        XCTAssertTrue(app.textFields["editor.title"].waitForExistence(timeout: 5))
        capture("04-editor")
        app.buttons["Cancel"].tap()
    }

    func testLaunchPerformance() {
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)"]
        measure(metrics: [XCTApplicationLaunchMetric()]) { app.launch() }
    }
}

//
//  LettresEtScoresUITests.swift
//  LettresEtScoresUITests
//
//  Created by Bart Jourquin on 06/08/2026.
//

import XCTest

final class LettresEtScoresUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testSearchAndOpenDefinition() throws {
        let app = XCUIApplication()

        app.launchArguments.append("--ui-testing")
        app.launch()

        let rackField =
            app.textFields["rackTextField"]

        XCTAssertTrue(
            rackField.waitForExistence(timeout: 5)
        )

        rackField.tap()
        rackField.typeText("CHATS")
        
        let form = scrollContainer(in: app)

        XCTAssertTrue(
            form.waitForExistence(timeout: 2),
            "Le formulaire reste introuvable."
        )

        if app.keyboards.firstMatch.exists {
            rackField.typeText("\n")
        }

        let searchButton =
            app.buttons["searchButton"]

        XCTAssertTrue(
            reveal(searchButton, byScrolling: form),
            "Le bouton Rechercher reste introuvable."
        )

        XCTAssertTrue(searchButton.isEnabled)
        searchButton.tap()

        let candidate =
            app.buttons["candidate.CHATS"]

        XCTAssertTrue(
            reveal(candidate, byScrolling: form),
            "Le candidat CHATS reste introuvable."
        )

        candidate.tap()

        XCTAssertTrue(
            app.navigationBars["CHATS"]
                .waitForExistence(timeout: 5)
        )

        let definition =
            app.staticTexts["definitionExtract"]

        XCTAssertTrue(
            definition.waitForExistence(timeout: 5)
        )

        XCTAssertEqual(
            definition.label,
            "Définition simulée pour CHATS."
        )

        let fullDefinitionLink =
            app.descendants(matching: .any)[
                "fullDefinitionLink"
            ]

        XCTAssertTrue(
            fullDefinitionLink.waitForExistence(timeout: 5)
        )

        XCTAssertEqual(
            fullDefinitionLink.label,
            "Ouvrir la page complète"
        )
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    private func scrollContainer(
        in app: XCUIApplication
    ) -> XCUIElement {
        let collectionView =
            app.collectionViews.firstMatch

        if collectionView.exists {
            return collectionView
        }

        let table = app.tables.firstMatch

        if table.exists {
            return table
        }

        return app
    }

    @MainActor
    private func reveal(
        _ element: XCUIElement,
        byScrolling container: XCUIElement,
        maximumSwipes: Int = 6
    ) -> Bool {
        for _ in 0..<maximumSwipes {
            if element.exists && element.isHittable {
                return true
            }

            container.swipeUp()
        }

        return element.exists && element.isHittable
    }
}

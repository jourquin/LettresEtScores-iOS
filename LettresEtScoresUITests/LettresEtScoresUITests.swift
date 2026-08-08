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

        let searchButton =
            app.descendants(matching: .any)[
                "searchButton"
            ]

        XCTAssertTrue(
            reveal(searchButton, in: app),
            "Le bouton Rechercher reste introuvable."
        )

        XCTAssertTrue(searchButton.isEnabled)
        searchButton.tap()

        let candidate =
            app.descendants(matching: .any)[
                "candidate.CHATS"
            ]

        XCTAssertTrue(
            reveal(candidate, in: app),
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
    private func reveal(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maximumSwipes: Int = 6
    ) -> Bool {
        for _ in 0..<maximumSwipes {
            if element.exists && element.isHittable {
                return true
            }

            app.swipeUp()
        }

        return element.exists && element.isHittable
    }
}

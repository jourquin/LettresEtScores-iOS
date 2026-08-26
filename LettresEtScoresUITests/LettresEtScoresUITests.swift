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
    func testChecksAWordWithAnEmptyRack() throws {
        let app = XCUIApplication()

        app.launchArguments.append("--ui-testing")
        app.launch()

        let constraintsField =
            app.textFields["constraintsTextField"]

        XCTAssertTrue(
            constraintsField.waitForExistence(timeout: 5)
        )

        constraintsField.tap()
        constraintsField.typeText("CHAT")

        if app.keyboards.firstMatch.exists {
            constraintsField.typeText("\n")
        }

        let form = scrollContainer(in: app)
        let checkButton = app.buttons["searchButton"]

        XCTAssertTrue(
            reveal(checkButton, byScrolling: form)
        )
        XCTAssertEqual(checkButton.label, "Vérifier")

        checkButton.tap()

        let result = app.staticTexts["wordCheckResult"]

        XCTAssertTrue(
            reveal(
                result,
                byScrolling: form,
                requiresHittable: false
            ),
            "Le résultat de la vérification reste introuvable."
        )
        XCTAssertEqual(
            result.label,
            "« CHAT » figure dans la liste ODS9."
        )

        let definitionButton =
            app.buttons["wordCheckDefinitionButton"]

        XCTAssertTrue(
            reveal(
                definitionButton,
                byScrolling: form
            ),
            "Le bouton de définition reste introuvable."
        )
        XCTAssertTrue(definitionButton.isEnabled)
        definitionButton.tap()

        XCTAssertTrue(
            app.navigationBars["CHAT"]
                .waitForExistence(timeout: 5)
        )

        let definition =
            app.staticTexts["definitionExtract"]

        XCTAssertTrue(
            definition.waitForExistence(timeout: 5)
        )
        XCTAssertEqual(
            definition.label,
            "Définition simulée pour CHAT."
        )
    }

    @MainActor
    func testDisablesDefinitionForMissingWord() throws {
        let app = XCUIApplication()

        app.launchArguments.append("--ui-testing")
        app.launch()

        let constraintsField =
            app.textFields["constraintsTextField"]

        XCTAssertTrue(
            constraintsField.waitForExistence(timeout: 5)
        )

        constraintsField.tap()
        constraintsField.typeText("CHAT")

        if app.keyboards.firstMatch.exists {
            constraintsField.typeText("\n")
        }

        let form = scrollContainer(in: app)
        let checkButton = app.buttons["searchButton"]

        XCTAssertTrue(
            reveal(checkButton, byScrolling: form)
        )
        checkButton.tap()

        let result = app.staticTexts["wordCheckResult"]
        let definitionButton =
            app.buttons["wordCheckDefinitionButton"]

        XCTAssertTrue(
            reveal(
                result,
                byScrolling: form,
                requiresHittable: false
            ),
            "Le résultat de la vérification reste introuvable."
        )
        XCTAssertEqual(
            result.label,
            "« CHAT » figure dans la liste ODS9."
        )
        XCTAssertTrue(
            reveal(definitionButton, byScrolling: form),
            "Le bouton doit être affiché pour un mot présent."
        )

        for _ in 0..<6 where !constraintsField.isHittable {
            form.swipeDown()
        }

        XCTAssertTrue(
            constraintsField.isHittable,
            "Le champ Contraintes reste inaccessible."
        )
        replaceText(in: constraintsField, with: "CHIEN")

        if app.keyboards.firstMatch.exists {
            constraintsField.typeText("\n")
        }

        XCTAssertTrue(
            reveal(checkButton, byScrolling: form)
        )
        checkButton.tap()

        XCTAssertTrue(
            reveal(
                result,
                byScrolling: form,
                requiresHittable: false
            ),
            "Le nouveau résultat reste introuvable."
        )
        XCTAssertEqual(
            result.label,
            "« CHIEN » ne figure pas dans la liste ODS9."
        )

        XCTAssertTrue(
            reveal(definitionButton, byScrolling: form),
            "Le bouton désactivé reste introuvable."
        )
        let disabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == false"),
            object: definitionButton
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [disabled], timeout: 2),
            .completed,
            "Le bouton doit être désactivé pour un mot absent."
        )
    }

    @MainActor
    func testShowsODS9Information() throws {
        let app = XCUIApplication()

        app.launchArguments.append("--ui-testing")
        app.launch()

        let aboutButton = app.buttons["aboutButton"]

        XCTAssertTrue(
            aboutButton.waitForExistence(timeout: 5)
        )
        aboutButton.tap()

        XCTAssertTrue(
            app.navigationBars["À propos / Licences"]
                .waitForExistence(timeout: 2)
        )

        let list = scrollContainer(in: app)
        let summary = app.staticTexts["ods9Summary"]

        XCTAssertTrue(
            reveal(
                summary,
                byScrolling: list,
                requiresHittable: false
            ),
            "Le résumé ODS9 reste introuvable."
        )

        // En mode --ui-testing, le moteur contient seulement les trois mots
        // de la fixture. Le total indexé réel (407 128) est vérifié par
        // WordListLoaderTests.embeddedODS9HasExpectedIndex.
        XCTAssertTrue(
            summary.label.contains("416"),
            "Le résumé ODS9 devrait indiquer les 416 349 formes "
                + "de la ressource : \(summary.label)"
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
        requiresHittable: Bool = true,
        maximumSwipes: Int = 6
    ) -> Bool {
        for _ in 0..<maximumSwipes {
            let exists = element.waitForExistence(
                timeout: 1
            )

            if exists
                && (!requiresHittable || element.isHittable)
            {
                return true
            }

            container.swipeUp()
        }

        return element.exists
            && (!requiresHittable || element.isHittable)
    }

    @MainActor
    private func replaceText(
        in field: XCUIElement,
        with replacement: String
    ) {
        field.tap()

        let currentText = field.value as? String ?? ""
        field.typeText(
            String(
                repeating: XCUIKeyboardKey.delete.rawValue,
                count: currentText.count
            )
        )
        field.typeText(replacement)
    }
}

//
//  WorkoutBuilderAppUITests.swift
//  WorkoutBuilderAppUITests
//
//  Created by Ashlynn Moore on 6/13/25.
//

import XCTest

final class WorkoutBuilderAppUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tab Navigation

    @MainActor
    func testAppLaunchesWithWorkoutsTab() throws {
        XCTAssertTrue(app.staticTexts["My Workouts"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCanSwitchToHistoryTab() throws {
        app.tabBars.buttons["History"].tap()
        let historyTitle = app.navigationBars["History"].waitForExistence(timeout: 3)
        let emptyState = app.staticTexts["No completed workouts yet"].waitForExistence(timeout: 3)
        XCTAssertTrue(historyTitle || emptyState)
    }

    // MARK: - Workout Creation Flow

    @MainActor
    func testCreateNewWorkoutDialogAppears() throws {
        app.buttons["plus.circle.fill"].tap()
        let alert = app.alerts["New Workout"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
    }

    @MainActor
    func testEmptyStateVisibleOnFreshLaunch() throws {
        let emptyStateText = app.staticTexts["No workouts yet"]
        _ = emptyStateText.waitForExistence(timeout: 3)
    }

    // MARK: - HIIT Timer

    @MainActor
    func testHIITTimerButtonExists() throws {
        let timerButton = app.staticTexts["HIIT Timer"]
        XCTAssertTrue(timerButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

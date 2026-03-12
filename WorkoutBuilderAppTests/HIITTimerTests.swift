//
//  HIITTimerTests.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 3/11/26.
//

import Testing
@testable import WorkoutBuilderApp

// @testable import gives tests access to internal types and methods
// that wouldn't normally be visible outside the app module

struct HIITTimerTests {
    
    // MARK: - Initial State
    // These tests confirm a brand new timer is set up correctly
    // before anything has happened to it
    
    @Test func timerInitializesWithDefaults() {
        // Arrange + Act — create a timer with the defaults only
        let timer = HIITTimer()
        
        // Assert — check every default value is what we expect
        #expect(timer.name == "HIIT Timer")
        #expect(timer.intervalDuration == 30)
        #expect(timer.totalDuration == 600)
        #expect(timer.isActive == false)
        #expect(timer.isPaused == false)
        #expect(timer.currentInterval == 1)
    }
    
    @Test func timerInitializesWithCustomValues() {
        // Arrange + Act
        let timer = HIITTimer(name: "Tabata", intervalDuration: 20, totalDuration: 240)
        
        // Assert
        #expect(timer.name == "Tabata")
        #expect(timer.intervalDuration == 20)
        #expect(timer.totalDuration == 240)
        // timeRemaining and intervalTimeRemaining should match
        // the durations passed in, not the defaults
        #expect(timer.timeRemaining == 240)
        #expect(timer.intervalTimeRemaining == 20)
    }
    
    // MARK: - Computed Properties
    // totalIntervals is calculated, not stored — worth testing separately
    
    @Test func totalIntervalsCalculatesCorrectly() {
        // 600 seconds total / 30 seconds per interval = 20 intervals
        let timer = HIITTimer(intervalDuration: 30, totalDuration: 600)
        #expect(timer.totalIntervals == 20)
    }
    
    @Test func totalIntervalsWithUnevenDivision() {
        // 300 / 45 = 6.66 — should truncate to 6, not round up
        let timer = HIITTimer(intervalDuration: 45, totalDuration: 300)
        #expect(timer.totalIntervals == 6)
    }
    
    @Test func progressPercentageStartsAtZero() {
        let timer = HIITTimer()
        #expect(timer.progressPercentage == 0.0)
    }
    
    @Test func intervalProgressPercentageStartsAtZero() {
        let timer = HIITTimer()
        #expect(timer.intervalProgressPercentage == 0.0)
    }
    
    // MARK: - Start
    
    @Test func startSetsIsActiveTrue() {
        var timer = HIITTimer()
        timer.start()
        #expect(timer.isActive == true)
        #expect(timer.isPaused == false)
    }
    
    // MARK: - Pause & Resume
    
    @Test func pauseSetsIsPausedTrue() {
        var timer = HIITTimer()
        timer.start()
        timer.pause()
        #expect(timer.isPaused == true)
        // isActive should still be true — paused is not stopped
        #expect(timer.isActive == true)
    }
    
    @Test func resumeClearsIsPaused() {
        var timer = HIITTimer()
        timer.start()
        timer.pause()
        timer.resume()
        #expect(timer.isPaused == false)
        #expect(timer.isActive == true)
    }
    
    // MARK: - Reset
    // Reset is important to test thoroughly — it touches a lot of state
    
    @Test func resetRestoresAllValuesToInitial() {
        var timer = HIITTimer(intervalDuration: 30, totalDuration: 600)
        
        // Simulate some progress
        timer.start()
        timer.timeRemaining = 200
        timer.intervalTimeRemaining = 10
        timer.currentInterval = 5
        
        // Act
        timer.reset()
        
        // Assert everything is back to its starting value
        #expect(timer.timeRemaining == 600)
        #expect(timer.intervalTimeRemaining == 30)
        #expect(timer.currentInterval == 1)
        #expect(timer.isActive == false)
        #expect(timer.isPaused == false)
    }
    
    // MARK: - Stop
    
    @Test func stopDeactivatesAndResetsTimer() {
        var timer = HIITTimer(intervalDuration: 30, totalDuration: 600)
        timer.start()
        timer.timeRemaining = 300
        timer.stop()
        
        // Stop should both deactivate AND reset
        #expect(timer.isActive == false)
        #expect(timer.timeRemaining == 600) // back to full duration
    }
    
    // MARK: - Format Helpers
    
    @Test func formatTimeShowsSecondsOnly() {
        // Under 1 minute should just show seconds
        #expect(HIITTimer.formatTime(30) == "30s")
        #expect(HIITTimer.formatTime(15) == "15s")
        #expect(HIITTimer.formatTime(45) == "45s")
    }
    
    @Test func formatTimeShowsMinutesOnly() {
        // Exact minutes should not show "0s"
        #expect(HIITTimer.formatTime(60) == "1m")
        #expect(HIITTimer.formatTime(600) == "10m")
        #expect(HIITTimer.formatTime(3600) == "60m")
    }
    
    @Test func formatTimeShowsMinutesAndSeconds() {
        #expect(HIITTimer.formatTime(90) == "1m 30s")
        #expect(HIITTimer.formatTime(75) == "1m 15s")
    }
    
    @Test func formatTimeForTimerPadsWithLeadingZeros() {
        // The active timer display should always show MM:SS format
        #expect(HIITTimer.formatTimeForTimer(65) == "01:05")
        #expect(HIITTimer.formatTimeForTimer(600) == "10:00")
        #expect(HIITTimer.formatTimeForTimer(9) == "00:09")
    }
    
    @Test func formatTimeForTimerHandlesZero() {
        #expect(HIITTimer.formatTimeForTimer(0) == "00:00")
    }
    
    @Test func formatTimeForTimerHandlesNegativeValues() {
        // The timer uses max(0, ...) so negative input should clamp to 00:00
        #expect(HIITTimer.formatTimeForTimer(-5) == "00:00")
    }
    
    // MARK: - Preset Values
    
    @Test func presetIntervalsAreInAscendingOrder() {
        let intervals = HIITTimer.presetIntervals
        #expect(intervals == intervals.sorted())
    }
    
    @Test func presetDurationsAreInAscendingOrder() {
        let durations = HIITTimer.presetDurations
        #expect(durations == durations.sorted())
    }
    
    @Test func presetIntervalsContainExpectedValues() {
        #expect(HIITTimer.presetIntervals.contains(15))
        #expect(HIITTimer.presetIntervals.contains(30))
        #expect(HIITTimer.presetIntervals.contains(60))
    }
}

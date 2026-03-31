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
        // Arrange + Act -- create a timer with the defaults only
        let timer = HIITTimer()
        
        // Assert -- check every default value is what we expect
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

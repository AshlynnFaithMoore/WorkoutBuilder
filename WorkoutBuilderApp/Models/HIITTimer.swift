//
//  HIITTimer.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/26/25.
//


import Foundation

// MARK: - Sound Options
enum HIITSoundOption: String, CaseIterable, Codable {
    case chime = "chime"
    case bell = "bell"
    case beep = "beep"
    case whistle = "whistle"
    case buzzer = "buzzer"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .chime: return "Chime"
        case .bell: return "Bell"
        case .beep: return "Beep"
        case .whistle: return "Whistle"
        case .buzzer: return "Buzzer"
        case .none: return "Silent"
        }
    }
    
    var fileName: String? {
        switch self {
        case .none: return nil
        default: return self.rawValue
        }
    }
}

// MARK: - Timer Mode
enum HIITTimerMode: String, Codable {
    case uniform   // all intervals same duration (original behavior)
    case workRest  // alternates between work and rest periods
}

// MARK: - Phase
// Tracks whether we're in a work or rest period
enum HIITPhase: String, Codable {
    case work
    case rest
    
    var displayName: String {
        switch self {
        case .work: return "WORK"
        case .rest: return "REST"
        }
    }
    
    var color: String {
        switch self {
        case .work: return "red"
        case .rest: return "blue"
        }
    }
    
    var next: HIITPhase {
        switch self {
        case .work: return .rest
        case .rest: return .work
        }
    }
}

// MARK: - Timer Model
struct HIITTimer: Identifiable, Codable {
    var id = UUID()
    var name: String
    var mode: HIITTimerMode = .uniform
    
    // Uniform mode
    var intervalDuration: TimeInterval
    
    // Work/Rest mode
    var workDuration: TimeInterval = 20
    var restDuration: TimeInterval = 10
    
    var totalDuration: TimeInterval
    var intervalSound: HIITSoundOption = .chime
    var completionSound: HIITSoundOption = .bell
    var isActive: Bool = false
    var isPaused: Bool = false
    var timeRemaining: TimeInterval
    var intervalTimeRemaining: TimeInterval
    var currentInterval: Int = 1
    var currentPhase: HIITPhase = .work  // only used in workRest mode
    
    init(name: String = "HIIT Timer", intervalDuration: TimeInterval = 30, totalDuration: TimeInterval = 600) {
        self.name = name
        self.intervalDuration = intervalDuration
        self.totalDuration = totalDuration
        self.timeRemaining = totalDuration
        self.intervalTimeRemaining = intervalDuration
    }
    
    // MARK: - Computed
    var totalIntervals: Int {
        switch mode {
        case .uniform:
            return Int(totalDuration / intervalDuration)
        case .workRest:
            let cycleLength = workDuration + restDuration
            return Int(totalDuration / cycleLength) * 2 // each cycle = 2 intervals
        }
    }
    
    var progressPercentage: Double {
        return (totalDuration - timeRemaining) / totalDuration
    }
    
    var intervalProgressPercentage: Double {
        let duration = currentIntervalDuration
        return (duration - intervalTimeRemaining) / duration
    }
    
    // Returns the duration of the current interval based on mode and phase
    var currentIntervalDuration: TimeInterval {
        switch mode {
        case .uniform:
            return intervalDuration
        case .workRest:
            return currentPhase == .work ? workDuration : restDuration
        }
    }
    
    // MARK: - Mutations
    mutating func reset() {
        timeRemaining = totalDuration
        intervalTimeRemaining = currentIntervalDuration
        currentInterval = 1
        currentPhase = .work
        isActive = false
        isPaused = false
    }
    
    mutating func start() {
        isActive = true
        isPaused = false
    }
    
    mutating func pause() { isPaused = true }
    mutating func resume() { isPaused = false }
    
    mutating func stop() {
        isActive = false
        isPaused = false
        reset()
    }
    
    // Called every second by the ViewModel — returns true if a phase/interval changed
    // so the ViewModel knows when to play a sound
    mutating func tick() -> TickResult {
        timeRemaining -= 1
        intervalTimeRemaining -= 1
        
        if timeRemaining <= 0 {
            return .completed
        }
        
        if intervalTimeRemaining <= 0 {
            currentInterval += 1
            
            switch mode {
            case .uniform:
                intervalTimeRemaining = intervalDuration
            case .workRest:
                currentPhase = currentPhase.next
                intervalTimeRemaining = currentIntervalDuration
            }
            return .intervalCompleted
        }
        
        return .ticking
    }
}

enum TickResult {
    case ticking         // normal tick, nothing special happened
    case intervalCompleted  // an interval just finished, play interval sound
    case completed       // total time is up, play completion sound
}

// MARK: - Presets
extension HIITTimer {
    static let presetIntervals: [TimeInterval] = [15, 30, 45, 60, 90, 120]
    static let presetDurations: [TimeInterval] = [60, 300, 600, 900, 1200, 1800, 2400, 3000, 3600]
    static let presetWorkDurations: [TimeInterval] = [10, 20, 30, 40, 45, 60]
    static let presetRestDurations: [TimeInterval] = [5, 10, 15, 20, 30, 45]
    
    static func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        if minutes > 0 {
            return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
    
    static func formatTimeForTimer(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(timeInterval))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

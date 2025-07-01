//
//  HIITTimer.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/26/25.
//


import Foundation


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
struct HIITTimer: Identifiable, Codable {
    var id = UUID()
    var name: String
    var intervalDuration: TimeInterval // in seconds (15 seconds to 2 minutes)
    var totalDuration: TimeInterval // in seconds (1 minute to 60 minutes)
    var intervalSound: HIITSoundOption = .chime // Add sound selection
    var completionSound: HIITSoundOption = .bell // Add completion sound selection
    var isActive: Bool = false
    var isPaused: Bool = false
    var timeRemaining: TimeInterval
    var intervalTimeRemaining: TimeInterval
    var currentInterval: Int = 1
    
    init(name: String = "HIIT Timer", intervalDuration: TimeInterval = 30, totalDuration: TimeInterval = 600) {
        self.name = name
        self.intervalDuration = intervalDuration
        self.totalDuration = totalDuration
        self.timeRemaining = totalDuration
        self.intervalTimeRemaining = intervalDuration
    }
    
    var totalIntervals: Int {
        return Int(totalDuration / intervalDuration)
    }
    
    var progressPercentage: Double {
        return (totalDuration - timeRemaining) / totalDuration
    }
    
    var intervalProgressPercentage: Double {
        return (intervalDuration - intervalTimeRemaining) / intervalDuration
    }
    
    mutating func reset() {
        timeRemaining = totalDuration
        intervalTimeRemaining = intervalDuration
        currentInterval = 1
        isActive = false
        isPaused = false
    }
    
    mutating func start() {
        isActive = true
        isPaused = false
    }
    
    mutating func pause() {
        isPaused = true
    }
    
    mutating func resume() {
        isPaused = false
    }
    
    mutating func stop() {
        isActive = false
        isPaused = false
        reset()
    }
}

// Preset intervals for easy selection
extension HIITTimer {
    static let presetIntervals: [TimeInterval] = [15, 30, 45, 60, 90, 120] // seconds
    static let presetDurations: [TimeInterval] = [60, 300, 600, 900, 1200, 1800, 2400, 3000, 3600] // 1min to 60min
    
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

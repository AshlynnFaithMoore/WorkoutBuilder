//
//  HIITTimerViewModel.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/26/25.
//


import Foundation
import Combine
import AVFoundation

class HIITTimerViewModel: ObservableObject {
    @Published var timer = HIITTimer()
    @Published var isShowingCustomization = false
    @Published var isShowingActiveTimer = false
    
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    init() {
        setupAudioSession()
        preloadSounds()
    }
    
    // MARK: - Timer Configuration
    func updateInterval(_ interval: TimeInterval) {
        timer.intervalDuration = interval
        if !timer.isActive {
            timer.intervalTimeRemaining = interval
        }
    }
    
    func updateTotalDuration(_ duration: TimeInterval) {
        timer.totalDuration = duration
        if !timer.isActive {
            timer.timeRemaining = duration
        }
    }
    
    func updateTimerName(_ name: String) {
        timer.name = name
    }
    
    func updateIntervalSound(_ sound: HIITSoundOption) {
            timer.intervalSound = sound
        }
        
    func updateCompletionSound(_ sound: HIITSoundOption) {
            timer.completionSound = sound
        }
    // MARK: - Timer Control
    func startTimer() {
        timer.start()
        isShowingActiveTimer = true
        isShowingCustomization = false
        startTimerLoop()
    }
    
    func pauseTimer() {
        if timer.isPaused {
            timer.resume()
            startTimerLoop()
        } else {
            timer.pause()
            stopTimerLoop()
        }
    }
    
    func stopTimer() {
        timer.stop()
        stopTimerLoop()
        isShowingActiveTimer = false
    }
    
    func resetTimer() {
        timer.reset()
    }
    
    // MARK: - Private Timer Logic
    private func startTimerLoop() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }
    
    private func stopTimerLoop() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func updateTimer() {
        guard timer.isActive && !timer.isPaused else { return }
        
        // Update time remaining
        timer.timeRemaining -= 1
        timer.intervalTimeRemaining -= 1
        
        // Check if interval is complete
        if timer.intervalTimeRemaining <= 0 {
            playSound(timer.intervalSound)
            timer.currentInterval += 1
            timer.intervalTimeRemaining = timer.intervalDuration
        }
        
        // Check if total time is complete
        if timer.timeRemaining <= 0 {
            completeTimer()
        }
    }
    
    private func completeTimer() {
        playSound(timer.completionSound) // Fixed: Use completion sound instead of interval sound
        stopTimer()
        // You could add completion actions here (notifications, etc.)
    }
    
    // MARK: - Audio Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func preloadSounds() {
            for soundOption in HIITSoundOption.allCases {
                guard let fileName = soundOption.fileName,
                      let soundURL = Bundle.main.url(forResource: fileName, withExtension: "wav") else {
                    continue
                }
                
                do {
                    let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                    audioPlayer.prepareToPlay()
                    audioPlayers[soundOption.rawValue] = audioPlayer
                } catch {
                    print("Failed to load sound \(fileName): \(error)")
                }
            }
        }
    private func playSound(_ soundOption: HIITSoundOption) {
            guard soundOption != .none else { return }
            
            if let audioPlayer = audioPlayers[soundOption.rawValue] {
                audioPlayer.stop()
                audioPlayer.currentTime = 0
                audioPlayer.play()
            } else {
                // Fallback to system sounds
                playSystemSound(for: soundOption)
            }
        }
        
        private func playSystemSound(for soundOption: HIITSoundOption) {
            let systemSoundID: SystemSoundID
            
            switch soundOption {
            case .chime:
                systemSoundID = 1016 // Short beep
            case .bell:
                systemSoundID = 1005 // Bell sound
            case .beep:
                systemSoundID = 1103 // Beep
            case .whistle:
                systemSoundID = 1016 // Fallback beep
            case .buzzer:
                systemSoundID = 1005 // Fallback bell
            case .none:
                return
            }
            
            AudioServicesPlaySystemSound(systemSoundID)
        }
        
        // Method to test sounds in customization view
        func testSound(_ soundOption: HIITSoundOption) {
            playSound(soundOption)
        }
        
        deinit {
            stopTimerLoop()
        }
    }

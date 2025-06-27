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
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        setupAudioSession()
        loadSystemSound()
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
            playChimeSound()
            timer.currentInterval += 1
            timer.intervalTimeRemaining = timer.intervalDuration
        }
        
        // Check if total time is complete
        if timer.timeRemaining <= 0 {
            completeTimer()
        }
    }
    
    private func completeTimer() {
        playCompletionSound()
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
    
    private func loadSystemSound() {
        // Using a system sound - you can replace this with a custom sound file
        guard let soundURL = Bundle.main.url(forResource: "chime", withExtension: "wav") else {
            // Fallback to system sound if custom sound not available
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Failed to load sound: \(error)")
        }
    }
    
    private func playChimeSound() {
        // Play system sound for interval chime
        AudioServicesPlaySystemSound(1016) // Short beep
    }
    
    private func playCompletionSound() {
        // Play system sound for completion
        AudioServicesPlaySystemSound(1005) // Completion sound
    }
    
    deinit {
        stopTimerLoop()
    }
}
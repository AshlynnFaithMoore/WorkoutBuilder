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
    
    // HealthKit session tracking
    @Published var heartRateSamples: [HeartRateSample] = []
    @Published var sessionCalories: Double = 0
    @Published var isShowingSessionSummary = false
    
    private var sessionStartDate: Date?
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let healthKit = HealthKitManager.shared
    
    init() {
        setupAudioSession()
        print("Bundle wav files:", Bundle.main.paths(forResourcesOfType: "wav", inDirectory: nil))
        preloadSounds()
    }
    
    // MARK: - Timer Configuration
    func updateInterval(_ interval: TimeInterval) {
        timer.intervalDuration = interval
        if !timer.isActive { timer.intervalTimeRemaining = interval }
    }
    
    func updateTotalDuration(_ duration: TimeInterval) {
        timer.totalDuration = duration
        if !timer.isActive { timer.timeRemaining = duration }
    }
    
    func updateTimerName(_ name: String) { timer.name = name }
    func updateIntervalSound(_ sound: HIITSoundOption) { timer.intervalSound = sound }
    func updateCompletionSound(_ sound: HIITSoundOption) { timer.completionSound = sound }
    
    // MARK: - Timer Control
    func startTimer() {
        sessionStartDate = Date()
        heartRateSamples = []
        sessionCalories = 0
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
    
    func resetTimer() { timer.reset() }
    
    // MARK: - Private Timer Logic
    private func startTimerLoop() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.updateTimer() }
    }
    
    private func stopTimerLoop() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func updateTimer() {
        guard timer.isActive && !timer.isPaused else { return }
        
        timer.timeRemaining -= 1
        timer.intervalTimeRemaining -= 1
        
        if timer.intervalTimeRemaining <= 0 {
            playSound(timer.intervalSound)
            timer.currentInterval += 1
            timer.intervalTimeRemaining = timer.intervalDuration
        }
        
        if timer.timeRemaining <= 0 {
            completeTimer()
        }
    }
    
    private func completeTimer() {
        playSound(timer.completionSound)
        stopTimerLoop()
        timer.isActive = false
        timer.isPaused = false
        isShowingActiveTimer = false
        
        // Fetch HealthKit data for the session and save the workout
        Task { await finishHealthKitSession() }
    }
    
    // MARK: - HealthKit Session
    private func finishHealthKitSession() async {
        guard let startDate = sessionStartDate else { return }
        let endDate = Date()
        
        // Fetch heart rate and calories that occurred during the session
        async let heartRates = healthKit.fetchHeartRate(from: startDate, to: endDate)
        async let calories = healthKit.fetchTodayCalories()
        
        let (fetchedHeartRates, fetchedCalories) = await (heartRates, calories)
        
        // Save the workout to Health app
        try? await healthKit.saveWorkout(
            name: timer.name,
            startDate: startDate,
            endDate: endDate,
            calories: fetchedCalories
        )
        
        await MainActor.run {
            self.heartRateSamples = fetchedHeartRates
            self.sessionCalories = fetchedCalories
            self.isShowingSessionSummary = true
        }
    }
    
    // MARK: - Computed Heart Rate Stats
    var averageHeartRate: Int {
        guard !heartRateSamples.isEmpty else { return 0 }
        return heartRateSamples.map { $0.bpm }.reduce(0, +) / heartRateSamples.count
    }
    
    var maxHeartRate: Int {
        heartRateSamples.map { $0.bpm }.max() ?? 0
    }
    
    // MARK: - Audio
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
                  let soundURL = Bundle.main.url(forResource: fileName, withExtension: "wav") else { continue }
            do {
                let player = try AVAudioPlayer(contentsOf: soundURL)
                player.prepareToPlay()
                audioPlayers[soundOption.rawValue] = player
            } catch {
                print("Failed to load sound \(fileName): \(error)")
            }
        }
    }
    
    private func playSound(_ soundOption: HIITSoundOption) {
        guard soundOption != .none else { return }
        if let player = audioPlayers[soundOption.rawValue] {
            player.stop()
            player.currentTime = 0
            player.play()
        } else {
            playSystemSound(for: soundOption)
        }
    }
    
    private func playSystemSound(for soundOption: HIITSoundOption) {
        let id: SystemSoundID
        switch soundOption {
        case .chime: id = 1016
        case .bell: id = 1005
        case .beep: id = 1103
        case .whistle, .buzzer: id = 1016
        case .none: return
        }
        AudioServicesPlaySystemSound(id)
    }
    
    func testSound(_ soundOption: HIITSoundOption) { playSound(soundOption) }
    
    deinit { stopTimerLoop() }
}

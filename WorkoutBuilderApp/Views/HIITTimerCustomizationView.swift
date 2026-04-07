//
//  HIITTimerCustomizationView.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/26/25.
//


import SwiftUI

struct HIITTimerCustomizationView: View {
    @ObservedObject var timerViewModel: HIITTimerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedIntervalIndex = 1
    @State private var selectedDurationIndex = 2
    @State private var selectedWorkIndex = 1      // default 20s
    @State private var selectedRestIndex = 1      // default 10s
    @State private var customTimerName = "HIIT Timer"
    @State private var selectedIntervalSound: HIITSoundOption = .chime
    @State private var selectedCompletionSound: HIITSoundOption = .bell
    @State private var selectedMode: HIITTimerMode = .uniform
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("HIIT Timer Setup")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Configure your high-intensity interval timer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 32) {
                        
                        // MARK: Timer Name
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Timer Name")
                                .font(.headline)
                            TextField("Enter timer name", text: $customTimerName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: customTimerName) { _, newValue in
                                    if newValue.count > 100 { customTimerName = String(newValue.prefix(100)) }
                                }
                        }
                        .padding(.horizontal)
                        
                        // MARK: Mode Toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Timer Mode")
                                .font(.headline)
                            
                            Picker("Mode", selection: $selectedMode) {
                                Text("Uniform").tag(HIITTimerMode.uniform)
                                Text("Work / Rest").tag(HIITTimerMode.workRest)
                            }
                            .pickerStyle(.segmented)
                            
                            Text(selectedMode == .uniform
                                 ? "All intervals are the same duration"
                                 : "Alternate between work and rest periods")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        // MARK: Interval Config -- shown based on mode
                        if selectedMode == .uniform {
                            uniformIntervalSection
                        } else {
                            TimerWorkRestSection(
                                selectedWorkIndex: $selectedWorkIndex,
                                selectedRestIndex: $selectedRestIndex
                            )
                        }
                        
                        // MARK: Total Duration (shared between modes)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Total Duration")
                                .font(.headline)
                            Text("How long the entire workout should last")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                ForEach(Array(HIITTimer.presetDurations.enumerated()), id: \.offset) { index, duration in
                                    Button(action: { selectedDurationIndex = index }) {
                                        Text(HIITTimer.formatTime(duration))
                                            .font(.system(.body, design: .monospaced))
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedDurationIndex == index ? Color.blue : Color(.systemGray5))
                                            )
                                            .foregroundColor(selectedDurationIndex == index ? .white : .primary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // MARK: Sound Settings
                        soundSection
                        
                        // MARK: Preview
                        TimerPreviewSection(
                            timerName: customTimerName,
                            selectedMode: selectedMode,
                            selectedIntervalIndex: selectedIntervalIndex,
                            selectedWorkIndex: selectedWorkIndex,
                            selectedRestIndex: selectedRestIndex,
                            selectedDurationIndex: selectedDurationIndex,
                            intervalSound: selectedIntervalSound,
                            completionSound: selectedCompletionSound
                        )
                    }
                }
                
                // MARK: Start Button
                Button(action: startTimer) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Timer")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await HealthKitManager.shared.requestAuthorization()
            }
            customTimerName = timerViewModel.timer.name
            selectedMode = timerViewModel.timer.mode
            selectedIntervalSound = timerViewModel.timer.intervalSound
            selectedCompletionSound = timerViewModel.timer.completionSound
            
            if let i = HIITTimer.presetIntervals.firstIndex(of: timerViewModel.timer.intervalDuration) {
                selectedIntervalIndex = i
            }
            if let i = HIITTimer.presetDurations.firstIndex(of: timerViewModel.timer.totalDuration) {
                selectedDurationIndex = i
            }
            if let i = HIITTimer.presetWorkDurations.firstIndex(of: timerViewModel.timer.workDuration) {
                selectedWorkIndex = i
            }
            if let i = HIITTimer.presetRestDurations.firstIndex(of: timerViewModel.timer.restDuration) {
                selectedRestIndex = i
            }
        }
    }
    
    // MARK: - Subviews
    
    private var uniformIntervalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Interval Duration")
                .font(.headline)
            Text("How long each interval should last")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(Array(HIITTimer.presetIntervals.enumerated()), id: \.offset) { index, interval in
                    Button(action: { selectedIntervalIndex = index }) {
                        Text(HIITTimer.formatTime(interval))
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedIntervalIndex == index ? Color.blue : Color(.systemGray5))
                            )
                            .foregroundColor(selectedIntervalIndex == index ? .white : .primary)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sound Settings")
                .font(.headline)
            
            VStack(spacing: 16) {
                soundRow(title: "Interval Sound", selection: $selectedIntervalSound)
                soundRow(title: "Completion Sound", selection: $selectedCompletionSound)
            }
        }
        .padding(.horizontal)
    }
    
    private func soundRow(title: String, selection: Binding<HIITSoundOption>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Menu {
                    ForEach(HIITSoundOption.allCases, id: \.self) { sound in
                        Button(sound.displayName) { selection.wrappedValue = sound }
                    }
                } label: {
                    HStack {
                        Text(selection.wrappedValue.displayName)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
                
                Button(action: { timerViewModel.testSound(selection.wrappedValue) }) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Preview sound")
                .disabled(selection.wrappedValue == .none)
            }
        }
    }
    
    // MARK: - Actions
    private func startTimer() {
        let finalName = customTimerName.isEmpty ? "HIIT Timer" : customTimerName
        timerViewModel.updateTimerName(finalName)
        timerViewModel.updateMode(selectedMode)
        timerViewModel.updateTotalDuration(HIITTimer.presetDurations[selectedDurationIndex])
        timerViewModel.updateIntervalSound(selectedIntervalSound)
        timerViewModel.updateCompletionSound(selectedCompletionSound)
        
        if selectedMode == .uniform {
            timerViewModel.updateInterval(HIITTimer.presetIntervals[selectedIntervalIndex])
        } else {
            timerViewModel.updateWorkDuration(HIITTimer.presetWorkDurations[selectedWorkIndex])
            timerViewModel.updateRestDuration(HIITTimer.presetRestDurations[selectedRestIndex])
        }
        
        timerViewModel.resetTimer()
        timerViewModel.startTimer()
    }
}








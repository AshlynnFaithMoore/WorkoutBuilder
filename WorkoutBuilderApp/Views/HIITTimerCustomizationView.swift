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
    
    @State private var selectedIntervalIndex = 1 // Default to 30 seconds
    @State private var selectedDurationIndex = 2 // Default to 10 minutes
    @State private var customTimerName = "HIIT Timer"
    @State private var selectedIntervalSound: HIITSoundOption = .chime
    @State private var selectedCompletionSound: HIITSoundOption = .bell
    
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
                        // Timer Name Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Timer Name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter timer name", text: $customTimerName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        // Interval Duration Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Interval Duration")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("How long each interval should last")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                ForEach(Array(HIITTimer.presetIntervals.enumerated()), id: \.offset) { index, interval in
                                    Button(action: {
                                        selectedIntervalIndex = index
                                    }) {
                                        VStack(spacing: 4) {
                                            Text(HIITTimer.formatTime(interval))
                                                .font(.system(.body, design: .monospaced))
                                                .fontWeight(.medium)
                                        }
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
                        
                        // Total Duration Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Total Duration")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("How long the entire workout should last?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                ForEach(Array(HIITTimer.presetDurations.enumerated()), id: \.offset) { index, duration in
                                    Button(action: {
                                        selectedDurationIndex = index
                                    }) {
                                        VStack(spacing: 4) {
                                            Text(HIITTimer.formatTime(duration))
                                                .font(.system(.body, design: .monospaced))
                                                .fontWeight(.medium)
                                        }
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
                        
                        // Sound Configuration Section
                        
                        VStack(alignment: .leading, spacing: 16) {
                                                    Text("Sound Settings")
                                                        .font(.headline)
                                                        .foregroundColor(.primary)
                                                    
                                                    VStack(spacing: 16) {
                                                        // Interval Sound Selection
                                                        VStack(alignment: .leading, spacing: 8) {
                                                            Text("Interval Sound")
                                                                .font(.subheadline)
                                                                .fontWeight(.medium)
                                                            
                                                            HStack {
                                                                Menu {
                                                                    ForEach(HIITSoundOption.allCases, id: \.self) { sound in
                                                                        Button(sound.displayName) {
                                                                            selectedIntervalSound = sound
                                                                        }
                                                                    }
                                                                } label: {
                                                                    HStack {
                                                                        Text(selectedIntervalSound.displayName)
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
                                                                
                                                                Button(action: {
                                                                    timerViewModel.testSound(selectedIntervalSound)
                                                                }) {
                                                                    Image(systemName: "play.circle.fill")
                                                                        .font(.title2)
                                                                        .foregroundColor(.blue)
                                                                }
                                                                .disabled(selectedIntervalSound == .none)
                                                            }
                                                        }
                                                        
                                                        // Completion Sound Selection
                                                        VStack(alignment: .leading, spacing: 8) {
                                                            Text("Completion Sound")
                                                                .font(.subheadline)
                                                                .fontWeight(.medium)
                                                            
                                                            HStack {
                                                                Menu {
                                                                    ForEach(HIITSoundOption.allCases, id: \.self) { sound in
                                                                        Button(sound.displayName) {
                                                                            selectedCompletionSound = sound
                                                                        }
                                                                    }
                                                                } label: {
                                                                    HStack {
                                                                        Text(selectedCompletionSound.displayName)
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
                                                                
                                                                Button(action: {
                                                                    timerViewModel.testSound(selectedCompletionSound)
                                                                }) {
                                                                    Image(systemName: "play.circle.fill")
                                                                        .font(.title2)
                                                                        .foregroundColor(.blue)
                                                                }
                                                                .disabled(selectedCompletionSound == .none)
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding(.horizontal)
                        
                        // Preview Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preview")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Timer Name:")
                                    Spacer()
                                    Text(customTimerName.isEmpty ? "HIIT Timer" : customTimerName)
                                        .fontWeight(.medium)
                                }
                                
                                HStack {
                                    Text("Interval Duration:")
                                    Spacer()
                                    Text(HIITTimer.formatTime(HIITTimer.presetIntervals[selectedIntervalIndex]))
                                        .fontWeight(.medium)
                                }
                                
                                HStack {
                                    Text("Total Duration:")
                                    Spacer()
                                    Text(HIITTimer.formatTime(HIITTimer.presetDurations[selectedDurationIndex]))
                                        .fontWeight(.medium)
                                }
                                
                                HStack {
                                    Text("Total Intervals:")
                                    Spacer()
                                    Text("\(Int(HIITTimer.presetDurations[selectedDurationIndex] / HIITTimer.presetIntervals[selectedIntervalIndex]))")
                                        .fontWeight(.medium)
                                }
                                HStack {
                                    Text("Interval Sound:")
                                    Spacer()
                                    Text(selectedIntervalSound.displayName)
                                    .fontWeight(.medium)
                                }
                                                                
                                HStack {
                                    Text("Completion Sound:")
                                    Spacer()
                                    Text(selectedCompletionSound.displayName)
                                    .fontWeight(.medium)
                                }
                            }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                // Start Timer Button
                Button(action: {
                    let finalName = customTimerName.isEmpty ? "HIIT Timer" : customTimerName
                    timerViewModel.updateTimerName(finalName)
                    timerViewModel.updateInterval(HIITTimer.presetIntervals[selectedIntervalIndex])
                    timerViewModel.updateTotalDuration(HIITTimer.presetDurations[selectedDurationIndex])
                    timerViewModel.updateIntervalSound(selectedIntervalSound)
                    timerViewModel.updateCompletionSound(selectedCompletionSound)
                    timerViewModel.resetTimer()
                    timerViewModel.startTimer()
                }) {
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            customTimerName = timerViewModel.timer.name
            selectedIntervalSound = timerViewModel.timer.intervalSound
            selectedCompletionSound = timerViewModel.timer.completionSound
        }
    }
}

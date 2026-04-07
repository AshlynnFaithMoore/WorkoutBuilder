//
//  TimerPreviewSection.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 4/3/26.
//


//
//  TimerPreviewSection.swift
//  WorkoutBuilderApp
//
//  Extracted from HIITTimerCustomizationView for readability.
//

import SwiftUI

// Displays a summary of the configured timer settings before starting.
struct TimerPreviewSection: View {
    let timerName: String
    let selectedMode: HIITTimerMode
    let selectedIntervalIndex: Int
    let selectedWorkIndex: Int
    let selectedRestIndex: Int
    let selectedDurationIndex: Int
    let intervalSound: HIITSoundOption
    let completionSound: HIITSoundOption

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)

            VStack(spacing: 8) {
                previewRow("Timer Name", timerName.isEmpty ? "HIIT Timer" : timerName)
                previewRow("Mode", selectedMode == .uniform ? "Uniform" : "Work / Rest")

                if selectedMode == .uniform {
                    previewRow("Interval", HIITTimer.formatTime(HIITTimer.presetIntervals[selectedIntervalIndex]))
                } else {
                    previewRow("Work", HIITTimer.formatTime(HIITTimer.presetWorkDurations[selectedWorkIndex]))
                    previewRow("Rest", HIITTimer.formatTime(HIITTimer.presetRestDurations[selectedRestIndex]))
                }

                previewRow("Total Duration", HIITTimer.formatTime(HIITTimer.presetDurations[selectedDurationIndex]))
                previewRow("Interval Sound", intervalSound.displayName)
                previewRow("Completion Sound", completionSound.displayName)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    private func previewRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }
}

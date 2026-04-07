//
//  TimerWorkRestSection.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 4/6/26.
//


//  Extracted from HIITTimerCustomizationView for readability.


import SwiftUI

// Displays work and rest duration pickers for work/rest timer mode.
struct TimerWorkRestSection: View {
    @Binding var selectedWorkIndex: Int
    @Binding var selectedRestIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                    Text("Work Duration")
                        .font(.headline)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(Array(HIITTimer.presetWorkDurations.enumerated()), id: \.offset) { index, duration in
                        Button(action: { selectedWorkIndex = index }) {
                            Text(HIITTimer.formatTime(duration))
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedWorkIndex == index ? Color.red : Color(.systemGray5))
                                )
                                .foregroundColor(selectedWorkIndex == index ? .white : .primary)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                    Text("Rest Duration")
                        .font(.headline)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(Array(HIITTimer.presetRestDurations.enumerated()), id: \.offset) { index, duration in
                        Button(action: { selectedRestIndex = index }) {
                            Text(HIITTimer.formatTime(duration))
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedRestIndex == index ? Color.blue : Color(.systemGray5))
                                )
                                .foregroundColor(selectedRestIndex == index ? .white : .primary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}


//
//  HIITSessionSummaryView.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 3/16/26.
//


import SwiftUI
import Charts

struct HIITSessionSummaryView: View {
    @ObservedObject var timerViewModel: HIITTimerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Completion header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("Workout Complete!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(timerViewModel.timer.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Stats row
                    HStack(spacing: 0) {
                        statCell(
                            value: "\(timerViewModel.timer.totalIntervals)",
                            label: "Intervals",
                            icon: "timer",
                            color: .blue
                        )
                        Divider().frame(height: 60)
                        statCell(
                            value: "\(timerViewModel.averageHeartRate > 0 ? "\(timerViewModel.averageHeartRate)" : "--")",
                            label: "Avg BPM",
                            icon: "heart.fill",
                            color: .red
                        )
                        Divider().frame(height: 60)
                        statCell(
                            value: "\(timerViewModel.maxHeartRate > 0 ? "\(timerViewModel.maxHeartRate)" : "--")",
                            label: "Max BPM",
                            icon: "heart.fill",
                            color: .orange
                        )
                        Divider().frame(height: 60)
                        statCell(
                            value: timerViewModel.sessionCalories > 0 ? String(format: "%.0f", timerViewModel.sessionCalories) : "--",
                            label: "Calories",
                            icon: "flame.fill",
                            color: .orange
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Heart rate chart — only shown if we got data
                    if !timerViewModel.heartRateSamples.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Heart Rate", systemImage: "heart.fill")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Chart(timerViewModel.heartRateSamples) { sample in
                                LineMark(
                                    x: .value("Time", sample.date),
                                    y: .value("BPM", sample.bpm)
                                )
                                .foregroundStyle(Color.red.gradient)
                                .interpolationMethod(.catmullRom)
                                
                                AreaMark(
                                    x: .value("Time", sample.date),
                                    y: .value("BPM", sample.bpm)
                                )
                                .foregroundStyle(Color.red.opacity(0.1).gradient)
                                .interpolationMethod(.catmullRom)
                            }
                            .chartYScale(domain: heartRateYDomain)
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                                    AxisGridLine()
                                    if let date = value.as(Date.self) {
                                        AxisValueLabel {
                                            Text(date.formatted(.dateTime.minute().second()))
                                                .font(.caption2)
                                        }
                                    }
                                }
                            }
                            .frame(height: 160)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    } else {
                        // Shown if HealthKit returned no heart rate data
                        VStack(spacing: 8) {
                            Image(systemName: "heart.slash")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("No heart rate data available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Wear Apple Watch during your session to track heart rate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Saved to Health confirmation
                    HStack(spacing: 8) {
                        Image(systemName: "heart.text.square.fill")
                            .foregroundColor(.red)
                        Text("Workout saved to Apple Health")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        timerViewModel.resetTimer()
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func statCell(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var heartRateYDomain: ClosedRange<Int> {
        let min = (timerViewModel.heartRateSamples.map { $0.bpm }.min() ?? 60) - 10
        let max = (timerViewModel.heartRateSamples.map { $0.bpm }.max() ?? 180) + 10
        return min...max
    }
}
//
//  HIITTimerActiveView.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/26/25.
//


import SwiftUI

struct HIITTimerActiveView: View {
    @ObservedObject var timerViewModel: HIITTimerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Timer Name
                Text(timerViewModel.timer.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Main Timer Display
                VStack(spacing: 24) {
                    // Total Time Remaining
                    VStack(spacing: 8) {
                        Text("Total Time Remaining")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(HIITTimer.formatTimeForTimer(timerViewModel.timer.timeRemaining))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    // Progress Ring for Total Time
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 8)
                            .frame(width: 200, height: 200)
                        
                        Circle()
                            .trim(from: 0, to: timerViewModel.timer.progressPercentage)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: timerViewModel.timer.progressPercentage)
                        
                        VStack(spacing: 4) {
                            Text("Interval \(timerViewModel.timer.currentInterval)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("of \(timerViewModel.timer.totalIntervals)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Current Interval Progress
                    VStack(spacing: 12) {
                        HStack {
                            Text("Current Interval")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(HIITTimer.formatTimeForTimer(timerViewModel.timer.intervalTimeRemaining))
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.semibold)
                        }
                        
                        // Interval Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: geometry.size.width * timerViewModel.timer.intervalProgressPercentage, height: 8)
                                    .cornerRadius(4)
                                    .animation(.linear(duration: 1), value: timerViewModel.timer.intervalProgressPercentage)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Control Buttons
                HStack(spacing: 24) {
                    // Stop Button
                    Button(action: {
                        timerViewModel.stopTimer()
                        dismiss()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                                .font(.title2)
                            Text("Stop")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                        .frame(width: 80, height: 80)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(40)
                    }
                    
                    // Pause/Resume Button
                    Button(action: {
                        timerViewModel.pauseTimer()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: timerViewModel.timer.isPaused ? "play.fill" : "pause.fill")
                                .font(.title2)
                            Text(timerViewModel.timer.isPaused ? "Resume" : "Pause")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .frame(width: 80, height: 80)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(40)
                    }
                    
                    // Reset Button
                    Button(action: {
                        timerViewModel.resetTimer()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title2)
                            Text("Reset")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                        .frame(width: 80, height: 80)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(40)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        timerViewModel.stopTimer()
                        dismiss()
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // Handle app going to background - could add local notifications here
        }
    }
}

#Preview {
    let viewModel = HIITTimerViewModel()
    viewModel.timer.timeRemaining = 300
    viewModel.timer.intervalTimeRemaining = 25
    viewModel.timer.currentInterval = 3
    viewModel.timer.isActive = true
    
    return HIITTimerActiveView(timerViewModel: viewModel)
}
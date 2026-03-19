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
    
    // Phase color drives the accent color throughout the view
    private var phaseColor: Color {
        guard timerViewModel.timer.mode == .workRest else { return .blue }
        return timerViewModel.timer.currentPhase == .work ? .red : .blue
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Timer name
                Text(timerViewModel.timer.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(spacing: 24) {
                    // Total time remaining
                    VStack(spacing: 8) {
                        Text("Total Time Remaining")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(HIITTimer.formatTimeForTimer(timerViewModel.timer.timeRemaining))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    // Progress ring — color changes with phase
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 8)
                            .frame(width: 200, height: 200)
                        
                        Circle()
                            .trim(from: 0, to: timerViewModel.timer.progressPercentage)
                            .stroke(phaseColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: timerViewModel.timer.progressPercentage)
                        
                        VStack(spacing: 4) {
                            // Show phase badge in work/rest mode
                            if timerViewModel.timer.mode == .workRest {
                                Text(timerViewModel.timer.currentPhase.displayName)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(phaseColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            Text("Interval \(timerViewModel.timer.currentInterval)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("of \(timerViewModel.timer.totalIntervals)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Current interval progress bar
                    VStack(spacing: 12) {
                        HStack {
                            Text(timerViewModel.timer.mode == .workRest
                                 ? timerViewModel.timer.currentPhase.displayName
                                 : "Current Interval")
                                .font(.headline)
                                .foregroundColor(timerViewModel.timer.mode == .workRest ? phaseColor : .secondary)
                            
                            Spacer()
                            
                            Text(HIITTimer.formatTimeForTimer(timerViewModel.timer.intervalTimeRemaining))
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.semibold)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(phaseColor)
                                    .frame(
                                        width: geometry.size.width * timerViewModel.timer.intervalProgressPercentage,
                                        height: 8
                                    )
                                    .cornerRadius(4)
                                    .animation(.linear(duration: 1), value: timerViewModel.timer.intervalProgressPercentage)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Control buttons
                HStack(spacing: 24) {
                    controlButton(
                        icon: "stop.fill",
                        label: "Stop",
                        color: .red
                    ) {
                        timerViewModel.stopTimer()
                        dismiss()
                    }
                    
                    controlButton(
                        icon: timerViewModel.timer.isPaused ? "play.fill" : "pause.fill",
                        label: timerViewModel.timer.isPaused ? "Resume" : "Pause",
                        color: .blue
                    ) {
                        timerViewModel.pauseTimer()
                    }
                    
                    controlButton(
                        icon: "arrow.counterclockwise",
                        label: "Reset",
                        color: .orange
                    ) {
                        timerViewModel.resetTimer()
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
        .onAppear {
            if !timerViewModel.timer.isActive {
                timerViewModel.resetTimer()
            }
        }
    }
    
    private func controlButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2)
                Text(label).font(.caption)
            }
            .foregroundColor(color)
            .frame(width: 80, height: 80)
            .background(color.opacity(0.1))
            .cornerRadius(40)
        }
    }
}

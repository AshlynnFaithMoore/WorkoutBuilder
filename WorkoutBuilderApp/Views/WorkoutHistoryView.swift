//
//  WorkoutHistoryView.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 3/16/26.
//

import SwiftUI
import Charts

struct WorkoutHistoryView: View {
    @ObservedObject var viewModel: WorkoutBuilderViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.completedWorkouts.isEmpty {
                        emptyState
                    } else {
                        streakCard
                        activityChart
                        categoryChart
                        exerciseCountList
                    }
                }
                .padding()
            }
            .navigationTitle("History")
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No completed workouts yet")
                .font(.title3)
                .foregroundColor(.gray)
            Text("Mark a workout as complete from My Workouts to start tracking your progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Streak Card
    private var streakCard: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(viewModel.currentStreak)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                Text("Week Streak")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 60)

            VStack(spacing: 4) {
                Text("\(viewModel.completedWorkouts.count)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                Text("Total Workouts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 60)

            VStack(spacing: 4) {
                Text("\(viewModel.completedWorkouts.flatMap { $0.exercises }.count)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                Text("Total Exercises")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Activity Bar Chart
    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity — Last 30 Days")
                .font(.headline)

            Chart(viewModel.workoutsPerDay, id: \.date) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Workouts", item.count)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine()
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3))
            }
            .frame(height: 160)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Category Donut Chart
    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise Categories")
                .font(.headline)

            HStack(alignment: .center, spacing: 24) {
                Chart(viewModel.categoryBreakdown, id: \.category) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.55),
                        angularInset: 2.0
                    )
                    .foregroundStyle(categoryColor(item.category))
                    .cornerRadius(4)
                }
                .frame(width: 140, height: 140)

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.categoryBreakdown, id: \.category) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .frame(width: 8, height: 8)
                                .foregroundStyle(categoryColor(item.category))
                            Text(item.category.rawValue)
                                .font(.caption)
                            Spacer()
                            Text("\(item.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Exercises Per Workout List
    private var exerciseCountList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workouts")
                .font(.headline)

            ForEach(viewModel.completedWorkouts.reversed()) { workout in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let date = workout.completedDate {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Text("\(workout.exercises.count) exercises")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                .padding(.vertical, 4)

                if workout.id != viewModel.completedWorkouts.first?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Helpers
    // Maps categories to consistent colors to match the donut chart legend
    private func categoryColor(_ category: ExerciseCategory) -> Color {
        switch category {
        case .chest: return .blue
        case .back: return .green
        case .legs: return .orange
        case .arms: return .red
        case .shoulders: return .purple
        case .core: return .yellow
        case .cardio: return .pink
        case .other: return .gray
        }
    }
}

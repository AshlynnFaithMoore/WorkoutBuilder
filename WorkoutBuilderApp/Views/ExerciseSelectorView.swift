//
//  Created by Ashlynn Moore on 6/22/25.
//


// ExerciseSelectorView.swift
// Exercise selection view - Shows exercises to add to workout
import SwiftUI

struct ExerciseSelectorView: View {
    @ObservedObject var viewModel: WorkoutBuilderViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: Exercise?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search by name, muscle, or equipment", text: $viewModel.searchText)
                        .autocorrectionDisabled()
                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(10)
                .background(Color(.systemGray5))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button("All") { viewModel.selectedCategory = nil }
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(viewModel.selectedCategory == nil ? Color.blue : Color(.systemGray5))
                            .foregroundColor(viewModel.selectedCategory == nil ? .white : .primary)
                            .cornerRadius(20)

                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            Button(category.rawValue) { viewModel.selectedCategory = category }
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(viewModel.selectedCategory == category ? Color.blue : Color(.systemGray5))
                                .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)

                // Results count
                if !viewModel.searchText.isEmpty {
                    HStack {
                        Text("\(viewModel.filteredExercises.count) results")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }

                // Error State
                if let errorMessage = viewModel.exerciseService.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Retry") {
                            viewModel.refreshExercises()
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }

                // Exercise List
                if viewModel.filteredExercises.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No exercises found")
                            .font(.headline).foregroundColor(.gray)
                        Text("Try a different search term or category")
                            .font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List(viewModel.filteredExercises) { exercise in
                        Button(action: { selectedExercise = exercise }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(exercise.category.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 8).padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onAppear {
                            if exercise.id == viewModel.filteredExercises.last?.id {
                                viewModel.exerciseService.loadMoreExercises()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(
                    exercise: exercise,
                    onAdd: {
                        viewModel.addExerciseToCurrentWorkout(exercise)
                        dismiss()
                    }
                )
            }
            .onDisappear {
                viewModel.searchText = ""
                viewModel.selectedCategory = nil
            }
        }
    }
}





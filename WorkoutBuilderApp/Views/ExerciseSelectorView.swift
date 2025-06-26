//
//  WorkoutBuilderView.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/22/25.
//


// ExerciseSelectorView.swift
// Exercise selection view - Shows exercises to add to workout

import SwiftUI

struct ExerciseSelectorView: View {
    @ObservedObject var viewModel: WorkoutBuilderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button("All") {
                            viewModel.selectedCategory = nil
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewModel.selectedCategory == nil ? Color.blue : Color(.systemGray5))
                        .foregroundColor(viewModel.selectedCategory == nil ? .white : .primary)
                        .cornerRadius(20)
                        
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            Button(category.rawValue) {
                                viewModel.selectedCategory = category
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedCategory == category ? Color.blue : Color(.systemGray5))
                            .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Exercise List
                List(viewModel.filteredExercises) { exercise in
                    Button(action: {
                        viewModel.addExerciseToCurrentWorkout(exercise)
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(exercise.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Text(exercise.category.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

//
//  ExerciseDetailView.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 3/17/26.
//

import SwiftUI

// MARK: - Animated Exercise Image
// Fetches both images for an exercise and crossfades between them
// to simulate a GIF effect. Works with the free-exercise-db which
// stores two static images per exercise (start and end position).
struct AnimatedExerciseImage: View {
    let urls: [URL]
    
    @State private var images: [UIImage] = []
    @State private var currentIndex = 0
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if images.isEmpty && isLoading {
                // Loading state
                ZStack {
                    Color(.systemGray6)
                    ProgressView()
                }
            } else if images.isEmpty {
                // Failed to load
                ZStack {
                    Color(.systemGray6)
                    VStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No image available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Show current frame with crossfade
                Image(uiImage: images[currentIndex])
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
                    .id(currentIndex) // forces SwiftUI to animate between frames
            }
        }
        .task {
            await loadImages()
            startAnimation()
        }
    }
    
    private func loadImages() async {
        let loaded = await ImageCache.shared.images(for: urls)
        await MainActor.run {
            images = loaded
            isLoading = false
        }
    }
    
    private func startAnimation() {
        // Only animate if we have more than one image
        guard urls.count > 1 else { return }
        
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            guard !images.isEmpty else { return }
            withAnimation(.easeInOut(duration: 0.4)) {
                currentIndex = (currentIndex + 1) % images.count
            }
        }
    }
}

// MARK: - Exercise Detail View
struct ExerciseDetailView: View {
    let exercise: Exercise
    let onAdd: (() -> Void)?  // nil when viewed outside of workout builder
    @Environment(\.dismiss) private var dismiss
    
    // The free-exercise-db stores images as relative paths
    // We prefix with the GitHub raw content URL to get the full URL
    private let imageBaseURL = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: Title (full name, no truncation)
                    Text(exercise.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // MARK: GIF / Image
                    gifSection

                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: Quick Stats Row
                        quickStatsRow
                        
                        Divider()
                        
                        // MARK: Muscles
                        musclesSection
                        
                        Divider()
                        
                        // MARK: Equipment
                        equipmentSection
                        
                        Divider()
                        
                        // MARK: Instructions
                        instructionsSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80) // prevent Add button from covering last instruction
                    
                    // MARK: Add to Workout Button
                    if let onAdd = onAdd {
                        Button(action: {
                            onAdd()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add to Workout")
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
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var gifSection: some View {
        Group {
            let urls = exercise.imageURLs.compactMap { path -> URL? in
                guard let url = URL(string: imageBaseURL + path) else { return nil }
                guard ImageCache.isValid(url: url) else { return nil }
                return url
            }
            
            if urls.isEmpty {
                ZStack {
                    Color(.systemGray6)
                    VStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No image available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
            } else {
                AnimatedExerciseImage(urls: urls)
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .background(Color(.systemGray6))
            }
        }
    }
    
    private var quickStatsRow: some View {
        HStack(spacing: 0) {
            statCell(
                value: exercise.level.capitalized,
                label: "Level",
                icon: "chart.bar.fill",
                color: levelColor(exercise.level)
            )
            Divider().frame(height: 44)
            statCell(
                value: exercise.category.rawValue,
                label: "Category",
                icon: "tag.fill",
                color: .blue
            )
            Divider().frame(height: 44)
            statCell(
                value: exercise.force?.capitalized ?? "N/A",
                label: "Force",
                icon: "arrow.up.arrow.down",
                color: .orange
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var musclesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Muscles")
                .font(.headline)
            
            if !exercise.primaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Primary")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    FlowLayout(items: exercise.primaryMuscles) { muscle in
                        muscleTag(muscle, color: .red)
                    }
                }
            }
            
            if !exercise.secondaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Secondary")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    FlowLayout(items: exercise.secondaryMuscles) { muscle in
                        muscleTag(muscle, color: .orange)
                    }
                }
            }
        }
    }
    
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Equipment")
                .font(.headline)
            
            if exercise.equipment.isEmpty {
                Text("No equipment needed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                FlowLayout(items: exercise.equipment) { item in
                    equipmentTag(item)
                }
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.headline)
            
            ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.blue)
                        .clipShape(Circle())
                    
                    Text(step)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
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
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func muscleTag(_ name: String, color: Color) -> some View {
        Text(name.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
    
    private func equipmentTag(_ name: String) -> some View {
        Text(name.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
    }
    
    private func levelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "expert": return .red
        default: return .gray
        }
    }
}

// MARK: - Flow Layout
// A simple tag cloud layout that wraps items onto new lines
// when they don't fit -- SwiftUI doesn't have this built in until iOS 16 (womp womp)
struct FlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    
    @State private var totalHeight: CGFloat = .zero
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var lastHeight: CGFloat = 0
        let itemSpacing: CGFloat = 8
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > geometry.size.width {
                            width = 0
                            height -= lastHeight + itemSpacing
                        }
                        lastHeight = d.height
                        let result = width
                        if item == items.last { width = 0 } else { width -= d.width + itemSpacing }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last { height = 0 }
                        return result
                    }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.onAppear { totalHeight = geo.size.height }
            }
        )
    }
}

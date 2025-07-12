//
//  ExerciseService.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 7/11/25.
//

import Foundation

class ExerciseService: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let exerciseURL = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json"
    
    init() {
        loadExercises()
    }
    
    func loadExercises() {
        // First try to load from cache
        if let cachedExercises = loadCachedExercises() {
            self.exercises = cachedExercises
            return
        }
        
        // If no cache, fetch from network
        fetchExercises()
    }
    
    func fetchExercises() {
        guard let url = URL(string: exerciseURL) else {
            errorMessage = "Invalid URL"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    // Fallback to sample exercises
                    self?.exercises = Exercise.sampleExercises
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    self?.exercises = Exercise.sampleExercises
                    return
                }
                
                do {
                    // Try to decode as array first
                    let decodedExercises = try JSONDecoder().decode([Exercise].self, from: data)
                    self?.exercises = decodedExercises
                    self?.cacheExercises(decodedExercises)
                } catch {
                    print("Decoding error: \(error)")
                    // Try alternative structure
                    do {
                        let response = try JSONDecoder().decode(ExerciseResponse.self, from: data)
                        self?.exercises = response.exercises
                        self?.cacheExercises(response.exercises)
                    } catch {
                        print("Alternative decoding error: \(error)")
                        self?.errorMessage = "Failed to decode exercises: \(error.localizedDescription)"
                        self?.exercises = Exercise.sampleExercises
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Caching
    private func cacheExercises(_ exercises: [Exercise]) {
        do {
            let data = try JSONEncoder().encode(exercises)
            UserDefaults.standard.set(data, forKey: "CachedExercises")
            UserDefaults.standard.set(Date(), forKey: "CachedExercisesDate")
        } catch {
            print("Failed to cache exercises: \(error)")
        }
    }
    
    private func loadCachedExercises() -> [Exercise]? {
        guard let cacheDate = UserDefaults.standard.object(forKey: "CachedExercisesDate") as? Date,
              Date().timeIntervalSince(cacheDate) < 86400 * 7, // Cache for 7 days
              let data = UserDefaults.standard.data(forKey: "CachedExercises") else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode([Exercise].self, from: data)
        } catch {
            print("Failed to load cached exercises: \(error)")
            return nil
        }
    }
    
    // MARK: - Filtering
    func exercises(for category: ExerciseCategory) -> [Exercise] {
        return exercises.filter { $0.category == category }
    }
    
    func exercises(for equipment: String) -> [Exercise] {
        return exercises.filter { $0.equipment.contains(equipment) }
    }
    
    func exercises(for level: String) -> [Exercise] {
        return exercises.filter { $0.level.lowercased() == level.lowercased() }
    }
    
    func search(query: String) -> [Exercise] {
        guard !query.isEmpty else { return exercises }
        
        return exercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(query) ||
            exercise.primaryMuscles.contains { $0.localizedCaseInsensitiveContains(query) } ||
            exercise.equipment.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    // Get unique values for filtering
    var availableEquipment: [String] {
        let allEquipment = exercises.flatMap { $0.equipment }
        return Array(Set(allEquipment)).sorted()
    }
    
    var availableLevels: [String] {
        let allLevels = exercises.map { $0.level }
        return Array(Set(allLevels)).sorted()
    }
}

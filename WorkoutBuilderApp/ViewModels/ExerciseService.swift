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
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 15.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    print("Network error: \(error)")
                    // Fallback to sample exercises
                    self?.exercises = Exercise.sampleExercises
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Invalid response"
                    self?.exercises = Exercise.sampleExercises
                    return
                }
                
                print("HTTP Status Code: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    self?.errorMessage = "HTTP Error: \(httpResponse.statusCode)"
                    self?.exercises = Exercise.sampleExercises
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    self?.exercises = Exercise.sampleExercises
                    return
                }
                
                print("Received data size: \(data.count) bytes")
                
                do {
                    // Try to decode as array first
                    let decodedExercises = try JSONDecoder().decode([Exercise].self, from: data)
                    print("Successfully decoded \(decodedExercises.count) exercises")
                    self?.exercises = decodedExercises
                    self?.cacheExercises(decodedExercises)
                } catch {
                    print("Decoding error: \(error)")
                    // Try alternative structure
                    do {
                        let response = try JSONDecoder().decode(ExerciseResponse.self, from: data)
                        print("Successfully decoded \(response.exercises.count) exercises from response wrapper")
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
            print("Cached \(exercises.count) exercises")
        } catch {
            print("Failed to cache exercises: \(error)")
        }
    }
    
    private func loadCachedExercises() -> [Exercise]? {
        guard let cacheDate = UserDefaults.standard.object(forKey: "CachedExercisesDate") as? Date,
              Date().timeIntervalSince(cacheDate) < 86400 * 7, // Cache for 7 days
              let data = UserDefaults.standard.data(forKey: "CachedExercises") else {
            print("No valid cached exercises found")
            return nil
        }
        
        do {
            let cachedExercises = try JSONDecoder().decode([Exercise].self, from: data)
            print("Loaded \(cachedExercises.count) cached exercises")
            return cachedExercises
        } catch {
            print("Failed to load cached exercises: \(error)")
            return nil
        }
    }
    
    // MARK: - Filtering Methods (Fixed naming conflict)
    func exercises(for category: ExerciseCategory) -> [Exercise] {
            return exercises.filter { $0.category == category }
        }
        
    func exercises(withEquipment equipment: String) -> [Exercise] {
            return exercises.filter { $0.equipment.contains(equipment) }
        }
        
    func exercises(atLevel level: String) -> [Exercise] {
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
    
    // MARK: - Utility Methods
    func refreshExercises() {
        fetchExercises()
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "CachedExercises")
        UserDefaults.standard.removeObject(forKey: "CachedExercisesDate")
        print("Cache cleared")
    }
    
    // MARK: - Debug Methods
    func validateExerciseData() {
        print("=== Exercise Data Validation ===")
        print("Total exercises: \(exercises.count)")
        
        if exercises.isEmpty {
            print("⚠️ No exercises loaded")
            return
        }
        
        var validationResults: [String] = []
        
        // Check for exercises with missing names
        let exercisesWithoutNames = exercises.filter { $0.name.isEmpty }
        if !exercisesWithoutNames.isEmpty {
            validationResults.append("⚠️ \(exercisesWithoutNames.count) exercises without names")
        }
        
        // Check for exercises with missing descriptions
        let exercisesWithoutDescriptions = exercises.filter { $0.description.isEmpty }
        if !exercisesWithoutDescriptions.isEmpty {
            validationResults.append("⚠️ \(exercisesWithoutDescriptions.count) exercises without descriptions")
        }
        
        // Check for exercises with no primary muscles
        let exercisesWithoutMuscles = exercises.filter { $0.primaryMuscles.isEmpty }
        if !exercisesWithoutMuscles.isEmpty {
            validationResults.append("⚠️ \(exercisesWithoutMuscles.count) exercises without primary muscles")
        }
        
        // Check for exercises with no equipment
        let exercisesWithoutEquipment = exercises.filter { $0.equipment.isEmpty }
        if !exercisesWithoutEquipment.isEmpty {
            validationResults.append("ℹ️ \(exercisesWithoutEquipment.count) exercises without equipment (bodyweight exercises)")
        }
        
        // Category distribution
        let categoryDistribution = Dictionary(grouping: exercises, by: { $0.category })
        print("Category distribution:")
        for (category, exercises) in categoryDistribution {
            print("  \(category.rawValue): \(exercises.count)")
        }
        
        // Level distribution
        let levelDistribution = Dictionary(grouping: exercises, by: { $0.level })
        print("Level distribution:")
        for (level, exercises) in levelDistribution {
            print("  \(level): \(exercises.count)")
        }
        
        if validationResults.isEmpty {
            print("✅ All exercises appear to be valid")
        } else {
            print("Validation issues found:")
            for result in validationResults {
                print("  \(result)")
            }
        }
        
        print("=== End Validation ===")
    }
    
    func testJSONParsing() {
        print("=== Testing JSON Parsing ===")
        
        guard let url = URL(string: exerciseURL) else {
            print("❌ Invalid URL")
            return
        }
        
        print("Testing URL: \(exerciseURL)")
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    return
                }
                
                print("✅ HTTP Status: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("❌ No data received")
                    return
                }
                
                print("✅ Data received: \(data.count) bytes")
                
                // Try to parse as JSON to check structure
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                    if let array = jsonObject as? [Any] {
                        print("✅ JSON is an array with \(array.count) items")
                        
                        // Check first item structure
                        if let firstItem = array.first as? [String: Any] {
                            print("First item keys: \(Array(firstItem.keys))")
                        }
                    } else if let dict = jsonObject as? [String: Any] {
                        print("✅ JSON is a dictionary with keys: \(Array(dict.keys))")
                    }
                } catch {
                    print("❌ JSON parsing error: \(error)")
                }
                
                // Try to decode as Exercise array
                do {
                    let exercises = try JSONDecoder().decode([Exercise].self, from: data)
                    print("✅ Successfully decoded \(exercises.count) exercises")
                } catch {
                    print("❌ Exercise decoding error: \(error)")
                    
                    // Try alternative structure
                    do {
                        let response = try JSONDecoder().decode(ExerciseResponse.self, from: data)
                        print("✅ Successfully decoded \(response.exercises.count) exercises from wrapper")
                    } catch {
                        print("❌ Alternative decoding error: \(error)")
                    }
                }
            }
        }.resume()
        
        print("=== End JSON Test ===")
    }
}

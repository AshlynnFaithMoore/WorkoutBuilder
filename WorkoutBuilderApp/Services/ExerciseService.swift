//
//  ExerciseService.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 7/11/25.
//


import Foundation

// for testing purposes
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}


class ExerciseService: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Controls how many exercises are exposed to the UI at once.
    @Published var displayLimit: Int = 50
    
    private let exerciseURL = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json"
    private let session: URLSessionProtocol  // ← use protocol, not concrete type

    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session  // ← inject the session
        Task { await loadExercises() }
    }

    // The subset of exercises currently displayed in the UI.
    // ncreases as the user scrolls via `loadMoreExercises()`.
    var displayedExercises: [Exercise] {
        Array(exercises.prefix(displayLimit))
    }

    // Reveals the next batch of exercises for lazy display.
    func loadMoreExercises() {
        guard displayLimit < exercises.count else { return }
        displayLimit += 50
    }

    // Whether more exercises are available beyond the current display limit.
    var hasMoreExercises: Bool {
        displayLimit < exercises.count
    }
    
    // MARK: - Load (cache first, then network)
    func loadExercises() async {
        if let cached = loadCachedExercises() {
            await MainActor.run { self.exercises = cached }
            return
        }
        await fetchExercises()
    }
    
    // MARK: - Network Fetch
    func fetchExercises() async {
            guard let url = URL(string: exerciseURL) else {
                await MainActor.run { self.errorMessage = "Invalid URL" }
                return
            }

            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }

            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 15.0

                let (data, response) = try await session.data(for: request) // ← self.session not URLSession.shared
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ExerciseServiceError.invalidResponse
                }
                guard httpResponse.statusCode == 200 else {
                    throw ExerciseServiceError.httpError(httpResponse.statusCode)
                }

                let decoded = try decodeExercises(from: data)
                cacheExercises(decoded)

                await MainActor.run {
                    self.exercises = decoded
                    self.isLoading = false
                }
            } catch {
                let message = errorMessage(for: error)
                await MainActor.run {
                    self.errorMessage = message
                    self.exercises = Self.loadBundledExercises()
                    self.isLoading = false
                }
            }
        }
    
    // MARK: - Decoding
    // Tries array format first, then falls back to wrapped { "exercises": [] } format
    private func decodeExercises(from data: Data) throws -> [Exercise] {
        do {
            return try JSONDecoder().decode([Exercise].self, from: data)
        } catch {
            let wrapper = try JSONDecoder().decode(ExerciseResponse.self, from: data)
            return wrapper.exercises
        }
    }
    
    // MARK: - Error Handling
    private func errorMessage(for error: Error) -> String {
        switch error {
        case ExerciseServiceError.invalidResponse:
            return String(localized: "Invalid server response")
        case ExerciseServiceError.httpError(let code):
            return String(localized: "HTTP error: \(code)")
        case is DecodingError:
            return String(localized: "Failed to decode exercises")
        default:
            return String(localized: "Network error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Caching
    private func cacheExercises(_ exercises: [Exercise]) {
        guard let data = try? JSONEncoder().encode(exercises) else { return }
        UserDefaults.standard.set(data, forKey: "CachedExercises")
        UserDefaults.standard.set(Date(), forKey: "CachedExercisesDate")
    }
    
    private func loadCachedExercises() -> [Exercise]? {
        guard
            let cacheDate = UserDefaults.standard.object(forKey: "CachedExercisesDate") as? Date,
            Date().timeIntervalSince(cacheDate) < 86400 * 7,
            let data = UserDefaults.standard.data(forKey: "CachedExercises"),
            let cached = try? JSONDecoder().decode([Exercise].self, from: data),
            !cached.isEmpty,
            cached.allSatisfy({ !$0.name.isEmpty && !$0.id.isEmpty })
        else { return nil }
        return cached
    }
    
    // MARK: - Filtering
    func exercises(for category: ExerciseCategory) -> [Exercise] {
        exercises.filter { $0.category == category }
    }
    
    func exercises(withEquipment equipment: String) -> [Exercise] {
        exercises.filter { $0.equipment.contains(equipment) }
    }
    
    func exercises(atLevel level: String) -> [Exercise] {
        exercises.filter { $0.level.lowercased() == level.lowercased() }
    }
    
    func search(query: String) -> [Exercise] {
        guard !query.isEmpty else { return exercises }
        return exercises.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.primaryMuscles.contains { $0.localizedCaseInsensitiveContains(query) } ||
            $0.equipment.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    var availableEquipment: [String] {
        Array(Set(exercises.flatMap { $0.equipment })).sorted()
    }
    
    var availableLevels: [String] {
        Array(Set(exercises.map { $0.level })).sorted()
    }
    
    // MARK: - Utilities
    func refreshExercises() {
        displayLimit = 50
        Task { await fetchExercises() }
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "CachedExercises")
        UserDefaults.standard.removeObject(forKey: "CachedExercisesDate")
    }

    // Loads exercises from the bundled fallback JSON file.
    // Used when both network and cache are unavailable.
    static func loadBundledExercises() -> [Exercise] {
        guard let url = Bundle.main.url(forResource: "fallback_exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let exercises = try? JSONDecoder().decode([Exercise].self, from: data),
              !exercises.isEmpty
        else {
            return Exercise.sampleExercises
        }
        return exercises
    }
    
    // MARK: - Debug
    #if DEBUG
    func validateExerciseData() {
        print("=== Exercise Data Validation ===")
        print("Total exercises: \(exercises.count)")
        guard !exercises.isEmpty else { print(" No exercises loaded"); return }
        
        let checks: [(String, [Exercise])] = [
            ("without names", exercises.filter { $0.name.isEmpty }),
            ("without descriptions", exercises.filter { $0.description.isEmpty }),
            ("without primary muscles", exercises.filter { $0.primaryMuscles.isEmpty }),
        ]
        for (label, subset) in checks where !subset.isEmpty {
            print(" \(subset.count) exercises \(label)")
        }
        
        Dictionary(grouping: exercises, by: { $0.category })
            .forEach { print("  \($0.key.rawValue): \($0.value.count)") }
        print("=== End Validation ===")
    }
    
    func testJSONParsing() {
        Task {
            do {
                guard let url = URL(string: exerciseURL) else { return }
                let (data, _) = try await URLSession.shared.data(from: url)
                let exercises = try decodeExercises(from: data)
                print("Successfully decoded \(exercises.count) exercises")
            } catch {
                print("Parsing error: \(error)")
            }
        }
    }
    #endif
}

// MARK: - Error Types
enum ExerciseServiceError: Error {
    case invalidResponse
    case httpError(Int)
}



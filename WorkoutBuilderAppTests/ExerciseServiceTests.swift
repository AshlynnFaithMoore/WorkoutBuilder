
//  ExerciseServiceTests.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 3/11/26.
//

import Testing
import Foundation
@testable import WorkoutBuilderApp

// MARK: - Mock Session

final class MockURLSession: URLSessionProtocol {
    var dataToReturn: Data
    var responseToReturn: URLResponse
    var errorToThrow: Error?
    
    init(data: Data = Data(), statusCode: Int = 200) {
        self.dataToReturn = data
        self.responseToReturn = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = errorToThrow { throw error }
        return (dataToReturn, responseToReturn)
    }
}

// MARK: - Helpers
// Reusable sample JSON so each test doesn't repeat itself
private func makeExerciseJSON(id: String = "test-001", name: String = "Push-up") -> Data {
    let json = """
    [
        {
            "id": "\(id)",
            "name": "\(name)",
            "primaryMuscles": ["chest"],
            "secondaryMuscles": ["triceps"],
            "equipment": ["body only"],
            "level": "beginner",
            "instructions": ["Get into position", "Lower yourself"],
            "images": [],
            "force": "push",
            "mechanic": "compound"
        }
    ]
    """
    return Data(json.utf8)
}

private func makeMultipleExercisesJSON() -> Data {
    let json = """
    [
        {
            "id": "001", "name": "Push-up",
            "primaryMuscles": ["chest"], "secondaryMuscles": [],
            "equipment": ["body only"], "level": "beginner",
            "instructions": ["Step 1"], "images": []
        },
        {
            "id": "002", "name": "Squat",
            "primaryMuscles": ["quadriceps"], "secondaryMuscles": [],
            "equipment": ["barbell"], "level": "intermediate",
            "instructions": ["Step 1"], "images": []
        },
        {
            "id": "003", "name": "Lat Pulldown",
            "primaryMuscles": ["lats"], "secondaryMuscles": [],
            "equipment": ["cable"], "level": "beginner",
            "instructions": ["Step 1"], "images": []
        }
    ]
    """
    return Data(json.utf8)
}

// MARK: - Tests
struct ExerciseServiceTests {

    // MARK: - Decoding
    // These tests confirm that valid JSON gets turned into Exercise objects correctly
    
    @Test func loadsExercisesFromValidJSON() async throws {
        // Arrange -- create a mock session that returns one exercise
        let session = MockURLSession(data: makeExerciseJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        
        // Act -- wait for the async fetch to complete
        await service.fetchExercises()
        
        // Assert
        #expect(service.exercises.count == 1)
        #expect(service.exercises.first?.name == "Push-up")
        #expect(service.errorMessage == nil)
        #expect(service.isLoading == false)
    }
    
    @Test func parsesExerciseCategoryFromPrimaryMuscle() async {
        let session = MockURLSession(data: makeExerciseJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        // "chest" in primaryMuscles should map to .chest category
        #expect(service.exercises.first?.category == .chest)
    }
    
    @Test func parsesMultipleExercises() async {
        let session = MockURLSession(data: makeMultipleExercisesJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        #expect(service.exercises.count == 3)
    }

    // MARK: - Error Handling
    // These tests confirm the service handles failures gracefully
    // and falls back to sample exercises rather than crashing
    
    @Test func setsErrorMessageOnHTTP404() async {
        let session = MockURLSession(data: Data(), statusCode: 404)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        #expect(service.errorMessage != nil)
        // Should fall back to sample data, not leave exercises empty
        #expect(!service.exercises.isEmpty)
    }
    
    @Test func setsErrorMessageOnNetworkFailure() async {
        let session = MockURLSession()
        session.errorToThrow = URLError(.notConnectedToInternet)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        #expect(service.errorMessage != nil)
        #expect(!service.exercises.isEmpty) // fallback to sample data
    }
    
    @Test func setsErrorMessageOnBadJSON() async {
        let badData = Data("this is not json at all".utf8)
        let session = MockURLSession(data: badData, statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        #expect(service.errorMessage != nil)
        #expect(!service.exercises.isEmpty) // fallback to sample data
    }
    
    @Test func isLoadingIsFalseAfterFetch() async {
        // isLoading should always be cleaned up regardless of success or failure
        let session = MockURLSession(data: makeExerciseJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        #expect(service.isLoading == false)
    }

    // MARK: - Search
    
    @Test func searchFindsExerciseByName() async {
        let session = MockURLSession(data: makeMultipleExercisesJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        let results = service.search(query: "squat")
        #expect(results.count == 1)
        #expect(results.first?.name == "Squat")
    }
    
    @Test func searchFindsExerciseByMuscle() async {
        let session = MockURLSession(data: makeMultipleExercisesJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        let results = service.search(query: "lats")
        #expect(results.count == 1)
        #expect(results.first?.name == "Lat Pulldown")
    }
    
    @Test func searchFindsExerciseByEquipment() async {
        let session = MockURLSession(data: makeMultipleExercisesJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        let results = service.search(query: "barbell")
        #expect(results.count == 1)
        #expect(results.first?.name == "Squat")
    }
    
    @Test func searchIsCaseInsensitive() async {
        let session = MockURLSession(data: makeExerciseJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        // All of these should find "Push-up"
        #expect(service.search(query: "PUSH").count == 1)
        #expect(service.search(query: "push").count == 1)
        #expect(service.search(query: "Push").count == 1)
    }
    
    @Test func emptySearchReturnsAllExercises() async {
        let session = MockURLSession(data: makeMultipleExercisesJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        let results = service.search(query: "")
        #expect(results.count == service.exercises.count)
    }
    
    @Test func searchWithNoMatchReturnsEmpty() async {
        let session = MockURLSession(data: makeExerciseJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        #expect(service.search(query: "zzznomatch").isEmpty)
    }

    // MARK: - Filtering
    
    @Test func filtersByCategory() async {
        let session = MockURLSession(data: makeMultipleExercisesJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        let chestExercises = service.exercises(for: .chest)
        #expect(chestExercises.allSatisfy { $0.category == .chest })
    }
    
    @Test func filtersByEquipment() async {
        let session = MockURLSession(data: makeMultipleExercisesJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        let barbellExercises = service.exercises(withEquipment: "barbell")
        #expect(barbellExercises.allSatisfy { $0.equipment.contains("barbell") })
    }
    
    @Test func filtersByLevel() async {
        let session = MockURLSession(data: makeMultipleExercisesJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        
        let beginnerExercises = service.exercises(atLevel: "beginner")
        #expect(beginnerExercises.allSatisfy { $0.level == "beginner" })
        #expect(!beginnerExercises.isEmpty)
    }

    // MARK: - Cache Behavior

    @Test func clearCacheRemovesCachedData() async {
        let session = MockURLSession(data: makeExerciseJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()

        service.clearCache()

        // After clearing, cached keys should be gone
        #expect(UserDefaults.standard.data(forKey: "CachedExercises") == nil)
        #expect(UserDefaults.standard.object(forKey: "CachedExercisesDate") == nil)
    }

    @Test func availableEquipmentReturnsSortedUniqueList() async {
        let session = MockURLSession(data: makeMultipleExercisesJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()

        let equipment = service.availableEquipment
        #expect(equipment == equipment.sorted())
        #expect(Set(equipment).count == equipment.count)
    }

    @Test func availableLevelsReturnsSortedUniqueList() async {
        let session = MockURLSession(data: makeMultipleExercisesJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()

        let levels = service.availableLevels
        #expect(levels == levels.sorted())
        #expect(Set(levels).count == levels.count)
    }

    // MARK: - Cache TTL and Offline Behavior (TEST-3)

    @Test func staleCacheIsIgnored() async {
        // Seed the cache with valid data but a date older than 7 days
        let session = MockURLSession(data: makeExerciseJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()

        // Backdate the cache timestamp to 8 days ago
        let staleDate = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        UserDefaults.standard.set(staleDate, forKey: "CachedExercisesDate")

        // Create a new service with a different mock that returns 3 exercises
        let freshSession = MockURLSession(data: makeMultipleExercisesJSON(), statusCode: 200)
        let freshService = ExerciseService(session: freshSession)
        await freshService.loadExercises()

        // Should have fetched from network (3 exercises) not stale cache (1)
        #expect(freshService.exercises.count == 3)

        // Cleanup
        service.clearCache()
    }

    @Test func validCacheIsUsedInsteadOfNetwork() async {
        // First, populate the cache by doing a real fetch
        let session = MockURLSession(data: makeExerciseJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()

        // Create a new service with a session that would return different data
        let differentSession = MockURLSession(data: makeMultipleExercisesJSON(), statusCode: 200)
        let cachedService = ExerciseService(session: differentSession)
        await cachedService.loadExercises()

        // Should have loaded from cache (1 exercise) not network (3)
        #expect(cachedService.exercises.count == 1)

        // Cleanup
        service.clearCache()
    }

    @Test func offlineFallsBackToBundledExercisesWhenCacheEmpty() async {
        // Clear any existing cache
        UserDefaults.standard.removeObject(forKey: "CachedExercises")
        UserDefaults.standard.removeObject(forKey: "CachedExercisesDate")

        // Create a service whose network request will fail
        let failingSession = MockURLSession()
        failingSession.errorToThrow = URLError(.notConnectedToInternet)
        let service = ExerciseService(session: failingSession)
        await service.fetchExercises()

        // Should have fallen back to bundled exercises (not empty)
        #expect(!service.exercises.isEmpty)
        #expect(service.errorMessage != nil)
    }

    @Test func refreshResetsCacheAndFetchesFresh() async {
        // Populate cache
        let session = MockURLSession(data: makeExerciseJSON(), statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()
        #expect(service.exercises.count == 1)

        // Change mock to return different data, then force refresh
        session.dataToReturn = makeMultipleExercisesJSON()
        await service.fetchExercises()

        #expect(service.exercises.count == 3)

        // Cleanup
        service.clearCache()
    }

    // MARK: - Display Batching (DATA-3)
    @Test func displayLimitControlsVisibleExercises() async {
            let session = MockURLSession(data: makeMultipleExercisesJSON(), statusCode: 200)
            let service = ExerciseService(session: session)
            await service.fetchExercises()

            #expect(service.displayedExercises.count == 3)
            #expect(service.hasMoreExercises == false)
        }

        @Test func loadMoreIncreasesDisplayLimit() async {
            let session = MockURLSession(data: makeMultipleExercisesJSON(), statusCode: 200)
            let service = ExerciseService(session: session)
            service.displayLimit = 1
            await service.fetchExercises()

            #expect(service.displayedExercises.count == 1)
            #expect(service.hasMoreExercises == true)

            service.loadMoreExercises()
            #expect(service.displayedExercises.count == 3)
        }
    }



   

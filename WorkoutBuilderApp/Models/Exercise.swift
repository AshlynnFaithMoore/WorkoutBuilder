//
//  Exercise.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/25/25.
//


// Exercise.swift
// Model file - Contains data structures

import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    var id: String // Changed from UUID to String to match JSON
    let name: String
    let category: ExerciseCategory
    let description: String
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: [String]
    let force: String?
    let level: String
    let mechanic: String?
    let instructions: [String]
    let imageURLs: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case primaryMuscles
        case secondaryMuscles
        case equipment
        case force
        case level
        case mechanic
        case instructions
        case imageURLs = "images"
    }
    
    
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            primaryMuscles = try container.decode([String].self, forKey: .primaryMuscles)
            secondaryMuscles = try container.decode([String].self, forKey: .secondaryMuscles)
            equipment = try container.decode([String].self, forKey: .equipment)
            force = try container.decodeIfPresent(String.self, forKey: .force)
            level = try container.decode(String.self, forKey: .level)
            mechanic = try container.decodeIfPresent(String.self, forKey: .mechanic)
            instructions = try container.decode([String].self, forKey: .instructions)
            imageURLs = try container.decode([String].self, forKey: .imageURLs)
            
            // Map primary muscles to our category enum
            let primaryMuscle = primaryMuscles.first?.lowercased() ?? ""
            category = ExerciseCategory.fromPrimaryMuscle(primaryMuscle)
            
            // Create description from instructions
            description = instructions.first ?? "No description available"
        }
        
        // Custom encoder
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(primaryMuscles, forKey: .primaryMuscles)
            try container.encode(secondaryMuscles, forKey: .secondaryMuscles)
            try container.encode(equipment, forKey: .equipment)
            try container.encodeIfPresent(force, forKey: .force)
            try container.encode(level, forKey: .level)
            try container.encodeIfPresent(mechanic, forKey: .mechanic)
            try container.encode(instructions, forKey: .instructions)
            try container.encode(imageURLs, forKey: .imageURLs)
        }
        
        // Convenience initializer for creating custom exercises
        init(id: String = UUID().uuidString, name: String, category: ExerciseCategory, description: String, primaryMuscles: [String] = [], secondaryMuscles: [String] = [], equipment: [String] = [], force: String? = nil, level: String = "beginner", mechanic: String? = nil, instructions: [String] = [], imageURLs: [String] = []) {
            self.id = id
            self.name = name
            self.category = category
            self.description = description
            self.primaryMuscles = primaryMuscles
            self.secondaryMuscles = secondaryMuscles
            self.equipment = equipment
            self.force = force
            self.level = level
            self.mechanic = mechanic
            self.instructions = instructions.isEmpty ? [description] : instructions
            self.imageURLs = imageURLs
        }
        
        // Static property for sample exercises (fallback)
        static let sampleExercises = [
            Exercise(name: "Push-ups", category: .chest, description: "Classic upper body exercise", primaryMuscles: ["chest"], level: "beginner"),
            Exercise(name: "Squats", category: .legs, description: "Lower body compound movement", primaryMuscles: ["quadriceps"], level: "beginner"),
            Exercise(name: "Plank", category: .core, description: "Core stability exercise", primaryMuscles: ["abdominals"], level: "beginner"),
            Exercise(name: "Bench Press", category: .chest, description: "Chest strengthening exercise", primaryMuscles: ["chest"], level: "intermediate"),
            Exercise(name: "Deadlifts", category: .legs, description: "Full body compound lift", primaryMuscles: ["hamstrings"], level: "intermediate"),
            Exercise(name: "Pull-ups", category: .back, description: "Upper body pulling exercise", primaryMuscles: ["lats"], level: "intermediate"),
            Exercise(name: "Shoulder Press", category: .shoulders, description: "Shoulder strengthening", primaryMuscles: ["shoulders"], level: "beginner"),
            Exercise(name: "Bicep Curls", category: .arms, description: "Bicep isolation exercise", primaryMuscles: ["biceps"], level: "beginner")
        ]
    }

    // Updated ExerciseCategory enum with muscle mapping
    enum ExerciseCategory: String, CaseIterable, Codable {
        case chest = "Chest"
        case back = "Back"
        case legs = "Legs"
        case arms = "Arms"
        case shoulders = "Shoulders"
        case core = "Core"
        case cardio = "Cardio"
        case other = "Other"
        
        // Map primary muscles from JSON to categories
        static func fromPrimaryMuscle(_ muscle: String) -> ExerciseCategory {
            switch muscle.lowercased() {
            case "chest", "pectorals":
                return .chest
            case "lats", "middle trapezius", "lower trapezius", "rhomboids", "rear deltoids":
                return .back
            case "quadriceps", "hamstrings", "glutes", "calves", "adductors", "abductors":
                return .legs
            case "biceps", "triceps", "forearms":
                return .arms
            case "shoulders", "anterior deltoids", "lateral deltoids", "posterior deltoids":
                return .shoulders
            case "abdominals", "obliques", "lower back":
                return .core
            default:
                return .other
            }
        }
    }

    // Response wrapper for the JSON API
    struct ExerciseResponse: Codable {
        let exercises: [Exercise]
    }

    // Alternative if the JSON structure is just an array
    typealias ExerciseArray = [Exercise]

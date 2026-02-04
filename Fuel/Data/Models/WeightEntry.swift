import Foundation
import SwiftData

/// Weight tracking entry model
/// Records weight measurements over time

@Model
public final class WeightEntry {
    // MARK: - Identifiers

    @Attribute(.unique) public var id: UUID

    // MARK: - Data

    public var weightKg: Double
    public var recordedAt: Date
    public var notes: String?

    // MARK: - Optional Measurements

    public var bodyFatPercentage: Double?
    public var muscleMassKg: Double?
    public var waterPercentage: Double?
    public var boneMassKg: Double?
    public var visceralFat: Int?
    public var metabolicAge: Int?

    // MARK: - Source

    public var source: WeightSource
    public var photoData: Data?

    // MARK: - Relationships

    public var user: User?

    // MARK: - Metadata

    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        weightKg: Double,
        recordedAt: Date = Date(),
        source: WeightSource = .manual
    ) {
        self.id = id
        self.weightKg = weightKg
        self.recordedAt = recordedAt
        self.source = source
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    public var weightLbs: Double {
        weightKg * 2.20462
    }

    public var displayWeight: String {
        String(format: "%.1f", weightKg)
    }

    public var displayWeightLbs: String {
        String(format: "%.1f", weightLbs)
    }

    public var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: recordedAt)
    }

    public var isToday: Bool {
        Calendar.current.isDateInToday(recordedAt)
    }

    // MARK: - Methods

    /// Calculate BMI given height in cm
    public func calculateBMI(heightCm: Double) -> Double {
        let heightM = heightCm / 100
        return weightKg / (heightM * heightM)
    }

    /// Get BMI category
    public func bmiCategory(heightCm: Double) -> BMICategory {
        let bmi = calculateBMI(heightCm: heightCm)
        return BMICategory.from(bmi: bmi)
    }
}

// MARK: - Weight Source

public enum WeightSource: String, Codable {
    case manual = "manual"
    case appleHealth = "apple_health"
    case smartScale = "smart_scale"
    case photo = "photo"

    public var displayName: String {
        switch self {
        case .manual: return "Manual Entry"
        case .appleHealth: return "Apple Health"
        case .smartScale: return "Smart Scale"
        case .photo: return "Photo"
        }
    }

    public var icon: String {
        switch self {
        case .manual: return "pencil"
        case .appleHealth: return "heart.fill"
        case .smartScale: return "scalemass"
        case .photo: return "camera"
        }
    }
}

// MARK: - BMI Category

public enum BMICategory: String, CaseIterable {
    case underweight
    case normal
    case overweight
    case obese

    public static func from(bmi: Double) -> BMICategory {
        switch bmi {
        case ..<18.5:
            return .underweight
        case 18.5..<25:
            return .normal
        case 25..<30:
            return .overweight
        default:
            return .obese
        }
    }

    public var displayName: String {
        switch self {
        case .underweight: return "Underweight"
        case .normal: return "Normal"
        case .overweight: return "Overweight"
        case .obese: return "Obese"
        }
    }

    public var color: String {
        switch self {
        case .underweight: return "warning"
        case .normal: return "success"
        case .overweight: return "warning"
        case .obese: return "error"
        }
    }
}

// MARK: - Weight Progress

/// Helper struct for tracking weight progress
public struct WeightProgress {
    public let startWeight: Double
    public let currentWeight: Double
    public let targetWeight: Double
    public let startDate: Date
    public let entries: [WeightEntry]

    public var totalChange: Double {
        currentWeight - startWeight
    }

    public var remainingToGoal: Double {
        currentWeight - targetWeight
    }

    public var progressPercentage: Double {
        guard startWeight != targetWeight else { return 100 }
        let totalNeeded = abs(targetWeight - startWeight)
        let achieved = abs(startWeight - currentWeight)
        return min((achieved / totalNeeded) * 100, 100)
    }

    public var averageWeeklyChange: Double {
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: startDate, to: Date()).weekOfYear ?? 1
        guard weeks > 0 else { return 0 }
        return totalChange / Double(weeks)
    }

    public var isOnTrack: Bool {
        // Losing weight: current should be less than start
        if targetWeight < startWeight {
            return currentWeight <= startWeight
        }
        // Gaining weight: current should be more than start
        else if targetWeight > startWeight {
            return currentWeight >= startWeight
        }
        // Maintaining: within 2% of target
        return abs(currentWeight - targetWeight) / targetWeight < 0.02
    }

    public var projectedWeeksToGoal: Int? {
        guard averageWeeklyChange != 0 else { return nil }
        let weeksNeeded = abs(remainingToGoal / averageWeeklyChange)
        return Int(ceil(weeksNeeded))
    }
}

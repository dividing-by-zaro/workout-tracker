import Foundation

struct CelebrationData {
    let workoutName: String
    let duration: String
    let durationSeconds: Int
    let totalVolume: Double
    let totalSets: Int
    let totalReps: Int
    let totalDistance: Double
    let workoutCount: Int
    let hasWeightStats: Bool
    let hasRepsStats: Bool
    let hasDistanceStats: Bool
    var personalRecords: [PersonalRecord]
}

struct PersonalRecord {
    let exerciseName: String
    let newBest: String
    let previousBest: String?
}

extension Int {
    var ordinalString: String {
        let suffix: String
        let ones = self % 10
        let tens = (self % 100) / 10

        if tens == 1 {
            suffix = "th"
        } else {
            switch ones {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(self)\(suffix)"
    }
}

import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    @Attribute(.unique) var name: String
    var exerciseType: ExerciseType
    var defaultRestSeconds: Int

    init(
        id: UUID = UUID(),
        name: String,
        exerciseType: ExerciseType = .strength,
        defaultRestSeconds: Int = 90
    ) {
        self.id = id
        self.name = name
        self.exerciseType = exerciseType
        self.defaultRestSeconds = defaultRestSeconds
    }
}

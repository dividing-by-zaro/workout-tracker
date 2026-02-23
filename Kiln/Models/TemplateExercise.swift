import Foundation
import SwiftData

@Model
final class TemplateExercise {
    var id: UUID
    var order: Int
    var defaultSets: Int
    var exercise: Exercise?
    var template: WorkoutTemplate?

    init(
        id: UUID = UUID(),
        order: Int = 0,
        defaultSets: Int = 3,
        exercise: Exercise? = nil,
        template: WorkoutTemplate? = nil
    ) {
        self.id = id
        self.order = order
        self.defaultSets = defaultSets
        self.exercise = exercise
        self.template = template
    }
}

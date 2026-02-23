import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    @Attribute(.unique) var name: String
    var exerciseType: ExerciseType
    var defaultRestSeconds: Int
    var bodyPart: BodyPart?
    var equipmentType: EquipmentType?

    var resolvedBodyPart: BodyPart {
        bodyPart ?? BodyPart.infer(from: name)
    }

    var resolvedEquipmentType: EquipmentType {
        equipmentType ?? EquipmentType.infer(from: name, fallback: exerciseType)
    }

    init(
        id: UUID = UUID(),
        name: String,
        exerciseType: ExerciseType = .strength,
        defaultRestSeconds: Int = 90,
        bodyPart: BodyPart? = nil,
        equipmentType: EquipmentType? = nil
    ) {
        self.id = id
        self.name = name
        self.exerciseType = exerciseType
        self.defaultRestSeconds = defaultRestSeconds
        self.bodyPart = bodyPart
        self.equipmentType = equipmentType
    }
}

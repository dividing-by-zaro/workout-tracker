import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var exerciseType: ExerciseType
    var defaultRestSeconds: Int
    var bodyPart: BodyPart?
    var equipmentType: EquipmentType?
    var notes: String?

    var resolvedBodyPart: BodyPart {
        bodyPart ?? BodyPart.infer(from: name)
    }

    var resolvedEquipmentType: EquipmentType {
        equipmentType ?? EquipmentType.infer(from: name, fallback: exerciseType)
    }

    /// Exercise identity is name + equipment type. Names are normalized so case,
    /// diacritics, and repeated whitespace do not create accidental duplicates.
    var identityKey: String {
        Self.identityKey(name: name, equipmentType: resolvedEquipmentType)
    }

    static func identityKey(name: String, equipmentType: EquipmentType) -> String {
        "\(normalizedName(name))\u{001F}\(equipmentType.rawValue)"
    }

    static func normalizedName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
    }

    init(
        id: UUID = UUID(),
        name: String,
        exerciseType: ExerciseType = .strength,
        defaultRestSeconds: Int = 120,
        bodyPart: BodyPart? = nil,
        equipmentType: EquipmentType? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.exerciseType = exerciseType
        self.defaultRestSeconds = defaultRestSeconds
        self.bodyPart = bodyPart
        self.equipmentType = equipmentType
        self.notes = notes
    }
}

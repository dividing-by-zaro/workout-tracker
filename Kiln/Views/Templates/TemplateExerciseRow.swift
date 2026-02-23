import SwiftUI
import SwiftData

struct TemplateExerciseRow: View {
    @Bindable var templateExercise: TemplateExercise

    var body: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)

            Text(templateExercise.exercise?.name ?? "Unknown")
                .font(.body)

            Spacer()

            Stepper("\(templateExercise.defaultSets) sets", value: $templateExercise.defaultSets, in: 1...10)
                .fixedSize()
        }
        .padding(.vertical, 4)
    }
}

import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                searchField
                    .padding(.bottom, 12)

                content

                Color.clear.frame(height: DesignSystem.Spacing.tabBarClearance)
            }
        }
        .brickWallBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ALL EXERCISES")
                .font(DesignSystem.Typography.eyebrow)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(DesignSystem.Colors.ink3)
            Text("Exercises")
                .font(DesignSystem.Typography.h1Display)
                .foregroundStyle(DesignSystem.Colors.ink)
                .lineSpacing(0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(DesignSystem.Colors.ink3)
            TextField("Search exercises", text: $searchText)
                .font(DesignSystem.Typography.sans(14, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.ink)
                .textFieldStyle(.plain)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DesignSystem.Colors.card)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(DesignSystem.Colors.cardEdge, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 14)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if exercises.isEmpty {
            emptyState
        } else if filteredExercises.isEmpty {
            searchEmptyState
        } else {
            list
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("No exercises yet.")
                .font(DesignSystem.Typography.italicBody)
                .foregroundStyle(DesignSystem.Colors.ink3)
            Text("Exercises will appear here once you complete a workout.")
                .font(DesignSystem.Typography.helper)
                .foregroundStyle(DesignSystem.Colors.ink3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.horizontal, 24)
    }

    private var searchEmptyState: some View {
        VStack(spacing: 6) {
            Text("No exercises match \u{201C}\(searchText)\u{201D}.")
                .font(DesignSystem.Typography.italicBody)
                .foregroundStyle(DesignSystem.Colors.ink3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.horizontal, 24)
    }

    private var list: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(filteredExercises.enumerated()), id: \.element.id) { index, exercise in
                NavigationLink {
                    ExerciseHistoryView(exercise: exercise)
                } label: {
                    row(for: exercise)
                }
                .buttonStyle(.plain)

                if index < filteredExercises.count - 1 {
                    Rectangle()
                        .fill(DesignSystem.Colors.hair)
                        .frame(height: 1)
                        .padding(.leading, 14)
                }
            }
        }
    }

    private func row(for exercise: Exercise) -> some View {
        HStack(spacing: 8) {
            Text(exercise.name)
                .font(DesignSystem.Typography.sans(15, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.ink)
            Spacer()
            Text(exercise.resolvedEquipmentType.displayName)
                .font(DesignSystem.Typography.helper)
                .foregroundStyle(DesignSystem.Colors.ink3)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.ink3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

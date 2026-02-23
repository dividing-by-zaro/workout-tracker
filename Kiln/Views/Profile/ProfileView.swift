import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Workout> { $0.isInProgress == false }) private var completedWorkouts: [Workout]

    @State private var isImporting = false
    @State private var importInProgress = false
    @State private var importResult: CSVImportResult?
    @State private var showImportResult = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Profile header
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(DesignSystem.Colors.primary)

                    Text("Isabel")
                        .font(DesignSystem.Typography.title)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("\(completedWorkouts.count) workouts")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.lg)

                // Chart
                WorkoutsPerWeekChart(workouts: completedWorkouts)
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
                    .cardShadow()
                    .padding(.horizontal, DesignSystem.Spacing.md)

                // Import section
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Button {
                        isImporting = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text(importInProgress ? "Importing..." : "Import from Strong CSV")
                        }
                        .font(DesignSystem.Typography.body)
                        .frame(maxWidth: .infinity)
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.surface)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                        .cardShadow()
                    }
                    .disabled(importInProgress)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
        .grainedBackground()
        .navigationTitle("Profile")
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("Import Complete", isPresented: $showImportResult) {
            Button("OK") {}
        } message: {
            if let r = importResult {
                Text("Created \(r.workoutsCreated) workouts from \(r.rowsImported) rows. \(r.rowsSkipped) rows skipped. \(r.exercisesCreated) exercises created. \(r.templatesCreated) templates created.")
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? String(contentsOf: url, encoding: .utf8) else { return }

        importInProgress = true

        Task {
            let importService = CSVImportService(modelContainer: modelContext.container)
            let importResult = await importService.importCSV(data)

            await MainActor.run {
                self.importResult = importResult
                self.importInProgress = false
                self.showImportResult = true
            }
        }
    }
}

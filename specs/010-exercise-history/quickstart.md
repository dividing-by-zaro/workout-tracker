# Quickstart: Exercise History Browser

**Feature**: 010-exercise-history
**Branch**: `010-exercise-history`

## What This Feature Does

Adds a new "Exercises" tab to the main tab bar. The tab shows all exercises in alphabetical order. Tapping an exercise shows every past workout where that exercise was performed, with full set details (weight, reps, etc.).

## Files to Create

| File | Purpose |
|------|---------|
| `Kiln/Views/Exercises/ExerciseListView.swift` | Main exercises tab — alphabetical list with search |
| `Kiln/Views/Exercises/ExerciseHistoryView.swift` | Detail view — past workout sessions for one exercise |

## Files to Modify

| File | Change |
|------|--------|
| `Kiln/Views/ContentView.swift` | Add 4th tab (Exercises) at tag 2, shift Profile to tag 3 |
| `Kiln/Design/DesignSystem.swift` | Add `Icon.exercises` constant |
| `project.yml` | Add new files to Kiln target sources (if not using glob) |

## No Changes Needed

- No new SwiftData models
- No backend changes
- No Live Activity changes
- No new dependencies

## Key Patterns to Follow

1. **Exercise list**: Mirror `ExercisePickerView` pattern — `@Query(sort: \Exercise.name)`, `.searchable()`, show name + equipment type
2. **History cards**: Mirror `WorkoutDetailView` pattern — reuse `setDetailLabel` display logic for equipment-type-aware set formatting
3. **Navigation**: Wrap in `NavigationStack`, use `NavigationLink` to push exercise history
4. **Design system**: Use `DesignSystem.Colors`, `DesignSystem.Typography`, `DesignSystem.Spacing`, card styling with `.cardShadow()` and grain overlay
5. **Empty states**: Follow existing patterns (centered text, secondary color)

## Build & Test

```bash
xcodegen generate   # After adding new Swift files
# Then build in Xcode (Cmd+R)
```

Manual testing:
1. Verify exercises tab appears with correct icon
2. Verify alphabetical ordering and search filtering
3. Tap an exercise with history — verify all past workout dates and sets appear
4. Tap an exercise with no history — verify empty state
5. Verify tab bar still shows 4 tabs with correct icons and labels

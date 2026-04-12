import AppIntents
import ActivityKit

extension CompleteSetIntent {
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            WorkoutSessionManager.shared?.completeCurrentSetFromIntent()
        }
        return .result()
    }
}

extension AdjustWeightIntent {
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            WorkoutSessionManager.shared?.adjustWeightFromIntent(delta: delta)
        }
        return .result()
    }
}

extension AdjustRepsIntent {
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            WorkoutSessionManager.shared?.adjustRepsFromIntent(delta: delta)
        }
        return .result()
    }
}

extension SkipRestIntent {
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            WorkoutSessionManager.shared?.skipRestTimerFromIntent()
        }
        return .result()
    }
}

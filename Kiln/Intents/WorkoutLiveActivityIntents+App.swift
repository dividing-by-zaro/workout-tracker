import AppIntents
import ActivityKit

extension CompleteSetIntent: LiveActivityIntent {
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            WorkoutSessionManager.shared?.completeCurrentSetFromIntent()
        }
        return .result()
    }
}

extension AdjustWeightIntent: LiveActivityIntent {
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            WorkoutSessionManager.shared?.adjustWeightFromIntent(delta: delta)
        }
        return .result()
    }
}

extension AdjustRepsIntent: LiveActivityIntent {
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            WorkoutSessionManager.shared?.adjustRepsFromIntent(delta: delta)
        }
        return .result()
    }
}

extension SkipRestIntent: LiveActivityIntent {
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            WorkoutSessionManager.shared?.skipRestTimerFromIntent()
        }
        return .result()
    }
}

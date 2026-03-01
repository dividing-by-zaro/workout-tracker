import AppIntents
import ActivityKit

extension CompleteSetIntent: LiveActivityIntent {
    func perform() async throws -> some IntentResult {
        // Complete the set and start the rest timer — updates live activity immediately
        await MainActor.run {
            WorkoutSessionManager.shared?.completeCurrentSetFromIntent()
        }

        // Keep the intent (and app process) alive for the rest duration
        // so we can fire the expiry and advance to the next set
        guard let endDate = await MainActor.run(body: {
            WorkoutSessionManager.shared?.restTimer.endDate
        }), endDate.timeIntervalSinceNow > 0 else {
            return .result()
        }

        try? await Task.sleep(for: .seconds(endDate.timeIntervalSinceNow + 0.5))

        // If the timer is still running and has expired, advance to next set with sound
        // (Skip or a new Complete may have already handled it — check first)
        await MainActor.run {
            WorkoutSessionManager.shared?.checkAndHandleExpiredTimer()
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

import AppIntents

extension CompleteSetIntent: LiveActivityIntent {
    func perform() async throws -> some IntentResult {
        .result()
    }
}

extension AdjustWeightIntent: LiveActivityIntent {
    func perform() async throws -> some IntentResult {
        .result()
    }
}

extension AdjustRepsIntent: LiveActivityIntent {
    func perform() async throws -> some IntentResult {
        .result()
    }
}

extension SkipRestIntent: LiveActivityIntent {
    func perform() async throws -> some IntentResult {
        .result()
    }
}

import AppIntents

struct CompleteSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete Set"
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
}

struct AdjustWeightIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Adjust Weight"
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @Parameter(title: "Delta")
    var delta: Double

    init() {
        self.delta = 0
    }

    init(delta: Double) {
        self.delta = delta
    }
}

struct AdjustRepsIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Adjust Reps"
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @Parameter(title: "Delta")
    var delta: Int

    init() {
        self.delta = 0
    }

    init(delta: Int) {
        self.delta = delta
    }
}

struct SkipRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip Rest"
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
}

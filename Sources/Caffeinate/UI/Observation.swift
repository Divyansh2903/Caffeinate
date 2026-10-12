import Observation

/// Runs `apply` now and again after any `@Observable` property it read changes.
@MainActor
func observeChanges(_ apply: @escaping @MainActor () -> Void) {
    withObservationTracking {
        apply()
    } onChange: {
        Task { @MainActor in
            observeChanges(apply)
        }
    }
}

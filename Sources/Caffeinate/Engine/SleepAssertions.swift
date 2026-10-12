import Foundation
import IOKit.pwr_mgt

/// Owns one IOPMAssertion per active `AwakeMode`. Not thread-safe; use from the main actor.
@MainActor
final class SleepAssertions {
    private var ids: [AwakeMode: IOPMAssertionID] = [:]
    private let reason = "Caffeinate menu bar app is keeping the Mac awake" as CFString

    var active: AwakeMode { AwakeMode(ids.keys) }

    /// Make the set of held assertions exactly match `modes`.
    func apply(_ modes: AwakeMode) {
        for mode in AwakeMode.all {
            let wanted = modes.contains(mode)
            let held = ids[mode] != nil
            if wanted && !held { create(mode) }
            if !wanted && held { release(mode) }
        }
    }

    func releaseAll() {
        for mode in Array(ids.keys) { release(mode) }
    }

    private func create(_ mode: AwakeMode) {
        var id = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            mode.assertionType as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &id
        )
        if result == kIOReturnSuccess {
            ids[mode] = id
        } else {
            NSLog("Caffeinate: failed to create assertion \(mode.assertionType): \(result)")
        }
    }

    private func release(_ mode: AwakeMode) {
        guard let id = ids.removeValue(forKey: mode) else { return }
        IOPMAssertionRelease(id)
    }
}

import Foundation
import XCTest
@testable import Caffeinate

@MainActor
final class SleepAssertionsTests: XCTestCase {
    /// Lines from `pmset -g assertions` that belong to this process.
    private func ownAssertionLines() throws -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "assertions"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let pid = "pid \(ProcessInfo.processInfo.processIdentifier)("
        return output.split(separator: "\n").map(String.init).filter { $0.contains(pid) }
    }

    func testApplyCreatesAndReleasesSystemAssertions() throws {
        let assertions = SleepAssertions()

        assertions.apply([.display, .systemIdle])
        XCTAssertEqual(assertions.active, [.display, .systemIdle])
        var lines = try ownAssertionLines()
        XCTAssertTrue(lines.contains { $0.contains("PreventUserIdleDisplaySleep") }, "\(lines)")
        XCTAssertTrue(lines.contains { $0.contains("PreventUserIdleSystemSleep") }, "\(lines)")
        XCTAssertFalse(lines.contains { $0.contains("PreventSystemSleep ") })

        // Changing modes while active swaps assertions without duplicating them.
        assertions.apply([.systemOnAC])
        XCTAssertEqual(assertions.active, [.systemOnAC])
        lines = try ownAssertionLines()
        XCTAssertFalse(lines.contains { $0.contains("PreventUserIdleDisplaySleep") }, "\(lines)")
        XCTAssertTrue(lines.contains { $0.contains("PreventSystemSleep") }, "\(lines)")

        assertions.releaseAll()
        XCTAssertTrue(assertions.active.isEmpty)
        XCTAssertTrue(try ownAssertionLines().isEmpty)
    }

    func testModeMetadata() {
        for mode in AwakeMode.all {
            XCTAssertFalse(mode.assertionType.isEmpty)
            XCTAssertFalse(mode.title.isEmpty)
        }
    }

    func testDurationFormatter() {
        XCTAssertEqual(DurationFormatter.compact(15 * 60), "15m")
        XCTAssertEqual(DurationFormatter.compact(65 * 60), "1h 05m")
        XCTAssertEqual(DurationFormatter.compact(48), "0:48")
        XCTAssertEqual(DurationFormatter.spoken(65 * 60), "1 hour 5 minutes")
        XCTAssertEqual(DurationFormatter.spoken(2 * 3600), "2 hours")
        XCTAssertEqual(DurationFormatter.spoken(30), "30 seconds")
    }
}

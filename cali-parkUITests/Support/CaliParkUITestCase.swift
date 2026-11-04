//
//  CaliParkUITestCase.swift
//  cali-parkUITests
//
//  The base class of every UI test.
//

import XCTest

// MARK: - CaliParkUITestCase
/// Stops a UI test at its first failure and gives it more time than the
/// test plan's 60 s default, which fits the unit tests. One flow takes about
/// 30 s locally but over a minute on a cold CI simulator; past the allowance
/// XCTest treats the test as hung and kills the app mid-flow.
@MainActor
class CaliParkUITestCase: XCTestCase {
    /// Four minutes. XCTest rounds up to whole minutes and caps the value at
    /// the test plan's `maximumTestExecutionTimeAllowance` (300 s).
    static let uiTestTimeAllowance: TimeInterval = 240

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        executionTimeAllowance = Self.uiTestTimeAllowance
    }
}

//
//  HomeGreetingTests.swift
//  cali-parkTests
//
//  The hero greeting by hour of the day.
//

import Testing
@testable import cali_park

@MainActor
struct HomeGreetingTests {
    @Test(arguments: [
        (5, "Dzień dobry"), (11, "Dzień dobry"),
        (12, "Cześć"), (17, "Cześć"),
        (18, "Dobry wieczór"), (21, "Dobry wieczór"),
        (22, "Dobrej nocy"), (0, "Dobrej nocy"), (2, "Dobrej nocy"), (4, "Dobrej nocy"),
    ])
    func greetingFollowsTheHour(hour: Int, expected: String) {
        #expect(HeroHeaderView.greeting(hour: hour) == expected)
    }
}

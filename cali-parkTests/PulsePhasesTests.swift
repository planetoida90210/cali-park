import Testing

@testable import cali_park

/// The "Rozpocznij" pulse plays a fixed number of beats, then stops.
struct PulsePhasesTests {
    @Test(arguments: [1, 2, 3, 5])
    func beatsAlternateFromRest(count: Int) {
        let phases = PulsePhases.beats(count)
        #expect(phases.count == count * 2)
        #expect(phases.first == false)
        #expect(phases.filter { $0 }.count == count)
        #expect(zip(phases, phases.dropFirst()).allSatisfy { $0 != $1 })
    }

    @Test(arguments: [0, -1])
    func noBeatsBelowOne(count: Int) {
        #expect(PulsePhases.beats(count) == [false])
    }

    @MainActor
    @Test func heroPulsesTwoToThreeTimes() {
        #expect((2...3).contains(HeroPlanTodayView.pulseBeats))
    }
}

import Foundation

// MARK: - LoggedSet
/// One set inside a workout log entry. `weight` (kg) stays optional —
/// the SetPad UI logs reps only for now, but the model is ready for it.
struct LoggedSet: Codable, Equatable, Hashable {
    var reps: Int
    var weight: Double?

    init(reps: Int, weight: Double? = nil) {
        self.reps = reps
        self.weight = weight
    }
}

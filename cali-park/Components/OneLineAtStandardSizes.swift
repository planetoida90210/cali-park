import SwiftUI

// MARK: - OneLineAtStandardSizes
/// One line, truncated, at the standard text sizes; as many lines as the text
/// needs at accessibility sizes, where one line would cut it to a word or two
/// ("Następny trening: Jut…").
private struct OneLineAtStandardSizes: ViewModifier {
    @Environment(\.dynamicTypeSize) private var typeSize

    func body(content: Content) -> some View {
        content.lineLimit(typeSize.isAccessibilitySize ? nil : 1)
    }
}

extension View {
    /// `.lineLimit(1)` that lifts at accessibility text sizes.
    func oneLineAtStandardSizes() -> some View {
        modifier(OneLineAtStandardSizes())
    }
}

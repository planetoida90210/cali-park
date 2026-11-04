import SwiftUI

// MARK: - ScaledIconFrame
/// A square frame for a decorative glyph, ring or badge. It is `side` points
/// at the default text size and grows with Dynamic Type together with the
/// glyph inside it, up to XXXL. At accessibility sizes it stays at its XXXL
/// size, so the room goes to the text next to it.
///
/// Use it through `.scaledIconFrame(_:relativeTo:)` in place of a fixed
/// `.frame(width:height:)`.
private struct ScaledIconFrame<Content: View>: View {
    @ScaledMetric private var side: CGFloat
    private let content: Content

    init(side: CGFloat, relativeTo textStyle: Font.TextStyle, content: Content) {
        _side = ScaledMetric(wrappedValue: side, relativeTo: textStyle)
        self.content = content
    }

    var body: some View {
        content.frame(width: side, height: side)
    }
}

extension View {
    /// A `side` × `side` frame that scales with Dynamic Type up to XXXL; see
    /// `ScaledIconFrame`. Only for decorative content: the cap also stops the
    /// text inside from growing past XXXL.
    func scaledIconFrame(_ side: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> some View {
        ScaledIconFrame(side: side, relativeTo: textStyle, content: self)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

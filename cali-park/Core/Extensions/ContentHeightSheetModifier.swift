import SwiftUI

// MARK: - ContentHeightSheetModifier
/// Sizes a sheet to its content's ideal height instead of a fixed detent, so a
/// tall layout (or a larger Dynamic Type size) is never cut off at the top the
/// way it is when forced into `.medium`.
struct ContentHeightSheetModifier: ViewModifier {
    @State private var contentHeight: CGFloat?

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                contentHeight = height
            }
            .presentationDetents(contentHeight.map { [.height($0)] } ?? [.medium])
    }
}

extension View {
    /// Presents this sheet at exactly the height its content needs.
    func presentationContentHeight() -> some View {
        modifier(ContentHeightSheetModifier())
    }
}

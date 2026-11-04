import SwiftUI

// MARK: - ExerciseIconView
/// Apple Watch Workout–style exercise icon: black `figure.*` glyph
/// on an accent-colored circle. Two sizes keep the list and the detail
/// screen consistent. The circle grows with Dynamic Type together with its
/// glyph, up to the largest non-accessibility size: the icon is decorative,
/// so at accessibility sizes the room goes to the text next to it.
struct ExerciseIconView: View {
    enum Size {
        case row
        case detail

        var glyphFont: Font {
            switch self {
            case .row: .appTitle3
            case .detail: .appLargeTitle
            }
        }
    }

    let symbolName: String
    let size: Size

    var body: some View {
        ExerciseIconCircle(symbolName: symbolName, size: size)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityHidden(true)
    }
}

// MARK: - ExerciseIconCircle
private struct ExerciseIconCircle: View {
    let symbolName: String
    let size: ExerciseIconView.Size

    @ScaledMetric(relativeTo: .title3) private var rowDiameter: CGFloat = 44
    @ScaledMetric(relativeTo: .largeTitle) private var detailDiameter: CGFloat = 80

    private var diameter: CGFloat {
        switch size {
        case .row: rowDiameter
        case .detail: detailDiameter
        }
    }

    var body: some View {
        Circle()
            .fill(Color.accent)
            .frame(width: diameter, height: diameter)
            .overlay {
                Image(systemName: symbolName)
                    .font(size.glyphFont)
                    .foregroundStyle(.black)
            }
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: 16) {
        ExerciseIconView(symbolName: "figure.climbing", size: .row)
        ExerciseIconView(symbolName: "figure.gymnastics", size: .detail)
    }
    .padding()
    .background(Color.appBackground)
}

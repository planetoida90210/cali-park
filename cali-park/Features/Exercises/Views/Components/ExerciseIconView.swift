import SwiftUI

// MARK: - ExerciseIconView
/// Apple Watch Workout–style exercise icon: black `figure.*` glyph
/// on an accent-colored circle. Two fixed sizes keep the list and the
/// detail screen consistent.
struct ExerciseIconView: View {
    enum Size {
        case row
        case detail

        var diameter: CGFloat {
            switch self {
            case .row: 44
            case .detail: 80
            }
        }

        var glyphFont: Font {
            switch self {
            case .row: .title3
            case .detail: .largeTitle
            }
        }
    }

    let symbolName: String
    let size: Size

    var body: some View {
        Circle()
            .fill(Color.accent)
            .frame(width: size.diameter, height: size.diameter)
            .overlay {
                Image(systemName: symbolName)
                    .font(size.glyphFont)
                    .foregroundStyle(.black)
            }
            .accessibilityHidden(true)
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

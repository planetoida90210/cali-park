import SwiftUI

// MARK: - AdaptiveDetailRow
/// A row's main text with short details (a date, a total, a count) on the
/// trailing edge. At accessibility text sizes the details move under the main
/// text, so the main text keeps the full width instead of breaking mid-word.
struct AdaptiveDetailRow<Main: View, Details: View>: View {
    @Environment(\.dynamicTypeSize) private var typeSize

    private let main: Main
    private let details: Details

    init(@ViewBuilder main: () -> Main, @ViewBuilder details: () -> Details) {
        self.main = main()
        self.details = details()
    }

    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                main
                VStack(alignment: .leading, spacing: 4) { details }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 12) {
                main
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 4) { details }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(alignment: .leading, spacing: 24) {
        ForEach([DynamicTypeSize.large, .accessibility3], id: \.self) { size in
            AdaptiveDetailRow {
                Text("Podciągnięcia").foregroundStyle(Color.textPrimary)
            } details: {
                Text("3 serie").foregroundStyle(Color.textSecondary)
            }
            .dynamicTypeSize(size)
        }
    }
    .padding()
    .background(Color.componentBackground)
    .preferredColorScheme(.dark)
}

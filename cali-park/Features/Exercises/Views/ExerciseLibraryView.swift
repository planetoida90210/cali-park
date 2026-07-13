import SwiftUI

// MARK: - ExerciseLibraryView
/// Placeholder tab until the exercises feature is built on the stabilized base.
struct ExerciseLibraryView: View {
    private let categories = ["Podstawowe", "Zaawansowane", "Ekspert"]
    private let exercises = ["Podciągnięcia", "Pompki", "Dipy", "Flagi", "Muscle-up"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Kategorie ćwiczeń")
                        .font(.title3)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        ForEach(categories, id: \.self) { category in
                            Text(category)
                                .font(.bodyMedium)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.componentBackground)
                                .foregroundColor(.accent)
                                .cornerRadius(20)
                        }
                    }

                    ForEach(exercises, id: \.self) { exercise in
                        exerciseRow(exercise)
                    }
                }
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Biblioteka ćwiczeń")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Row
    private func exerciseRow(_ exercise: String) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.componentBackground)
            .frame(height: 100)
            .overlay(
                HStack {
                    Image(systemName: "figure.gymnastics")
                        .font(.system(size: 30))
                        .foregroundColor(.accent)

                    VStack(alignment: .leading) {
                        Text(exercise)
                            .font(.bodyLarge)
                            .foregroundColor(.textPrimary)

                        Text("Grupa mięśniowa: Przykładowa")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.accent)
                }
                .padding()
            )
    }
}

// MARK: - Preview
#Preview {
    ExerciseLibraryView()
        .preferredColorScheme(.dark)
}

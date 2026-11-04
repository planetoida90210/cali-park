import SwiftUI

// MARK: - AboutView
/// "O apce": the sources of the ladders and programs, the health note, the
/// map data credit, and the version and build number.
struct AboutView: View {
    var version: AppVersion = .current

    var body: some View {
        List {
            Section {
                sourceRows(AboutContent.ladderSources)
            } header: {
                Text("Źródła drabin")
            } footer: {
                Text(AboutContent.disclaimer)
            }
            .listRowBackground(Color.componentBackground)

            Section("Źródła programów") {
                sourceRows(AboutContent.programSources)
            }
            .listRowBackground(Color.componentBackground)

            Section("Zdrowie") {
                Text(AboutContent.healthNote)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
            }
            .listRowBackground(Color.componentBackground)

            Section("Mapa") {
                sourceRows([AboutContent.mapAttribution])
            }
            .listRowBackground(Color.componentBackground)

            Section {
                LabeledContent("Wersja", value: version.version)
                LabeledContent("Kompilacja", value: version.build)
            }
            .listRowBackground(Color.componentBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("O apce")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sourceRows(_ sources: [AboutSource]) -> some View {
        ForEach(sources) { source in
            Link(destination: source.url) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(source.displayName)
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textPrimary)
                    Text(source.usage)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .accessibilityHint("Otwiera stronę źródła")
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { AboutView() }
        .preferredColorScheme(.dark)
}

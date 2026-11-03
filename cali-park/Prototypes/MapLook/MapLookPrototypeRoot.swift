#if DEBUG
// PROTOTYPE — throwaway. Ticket: docs/wayfinder/calipark-1.0/tickets/011-map-look.md
//
// Launch arguments (DEBUG builds only):
//   -PrototypeMapLook            show the variant picker instead of the app
//   -MapLookVariant A|B|C        open one variant straight away
//   -MapLookSelect <park id>     preselect a Park (0–24), used for screenshots
//   -MapLookClean                hide the prototype switcher bar, used for screenshots

import SwiftUI

// MARK: - Variants

enum MapLookVariant: String, CaseIterable, Identifiable {
    case muted = "A"
    case sporty = "B"
    case listFirst = "C"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .muted: "Wyciszona"
        case .sporty: "Sportowa"
        case .listFirst: "Lista najpierw"
        }
    }

    var summary: String {
        switch self {
        case .muted: "Stonowana mapa, własne pinezki ze sprzętem, grupowanie i mała karta Parku na dole."
        case .sporty: "Satelita z rzeźbą terenu, duże neonowe pinezki i karuzela kart zsynchronizowana z mapą."
        case .listFirst: "Mała mapa u góry, pod nią lista najbliższych Parków z odległością."
        }
    }

    var next: MapLookVariant {
        let all = Self.allCases
        return all[(all.firstIndex(of: self)! + 1) % all.count]
    }

    var previous: MapLookVariant {
        let all = Self.allCases
        return all[(all.firstIndex(of: self)! + all.count - 1) % all.count]
    }
}

// MARK: - Launch options

struct MapLookLaunchOptions {
    let isEnabled: Bool
    let variant: MapLookVariant?
    let selectedParkID: Int?
    let hidesSwitcher: Bool

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        func value(after flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
            return arguments[index + 1]
        }
        isEnabled = arguments.contains("-PrototypeMapLook")
        variant = value(after: "-MapLookVariant").flatMap(MapLookVariant.init(rawValue:))
        selectedParkID = value(after: "-MapLookSelect").flatMap(Int.init)
        hidesSwitcher = arguments.contains("-MapLookClean")
    }
}

// MARK: - Root

struct MapLookPrototypeRoot: View {
    let options: MapLookLaunchOptions
    @State private var variant: MapLookVariant?

    init(options: MapLookLaunchOptions) {
        self.options = options
        _variant = State(initialValue: options.variant)
    }

    var body: some View {
        Group {
            if let variant {
                MapLookVariantHost(variant: variant, selectedParkID: options.selectedParkID)
                    .id(variant)
                    .safeAreaInset(edge: .top, spacing: 0) {
                        if !options.hidesSwitcher {
                            MapLookSwitcherBar(variant: $variant)
                        }
                    }
            } else {
                MapLookPickerView(variant: $variant)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct MapLookVariantHost: View {
    let variant: MapLookVariant
    let selectedParkID: Int?

    var body: some View {
        switch variant {
        case .muted: MapLookMutedVariant(initialSelection: selectedParkID)
        case .sporty: MapLookSportyVariant(initialSelection: selectedParkID)
        case .listFirst: MapLookListFirstVariant(initialSelection: selectedParkID)
        }
    }
}

// MARK: - Picker

private struct MapLookPickerView: View {
    @Binding var variant: MapLookVariant?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(MapLookVariant.allCases) { option in
                        Button {
                            variant = option
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(option.rawValue) · \(option.title)")
                                    .font(.headline)
                                    .foregroundStyle(Color.textPrimary)
                                Text(option.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } footer: {
                    Text("Prototyp do ticketu „Wygląd mapy parków”. Dane Parków są zmyślone.")
                }
            }
            .navigationTitle("Wygląd mapy")
        }
    }
}

// MARK: - Switcher bar

/// Deliberately looks unlike the app (white pill) so it reads as prototype chrome.
private struct MapLookSwitcherBar: View {
    @Binding var variant: MapLookVariant?

    var body: some View {
        if let current = variant {
            HStack(spacing: 4) {
                Button("Poprzedni wariant", systemImage: "chevron.left") {
                    variant = current.previous
                }
                Text("\(current.rawValue) · \(current.title)")
                    .font(.footnote.monospaced())
                    .frame(minWidth: 150)
                Button("Następny wariant", systemImage: "chevron.right") {
                    variant = current.next
                }
                Button("Lista wariantów", systemImage: "xmark") {
                    variant = nil
                }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white, in: .capsule)
            .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)
        }
    }
}
#endif

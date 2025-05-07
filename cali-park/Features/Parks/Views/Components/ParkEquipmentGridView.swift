import SwiftUI

// MARK: - ParkEquipmentGridView
/// Bogatsza reprezentacja wyposażenia – maks. 9 pozycji w eleganckiej, adaptacyjnej siatce.
/// Każda komórka: okrąg z gradientem + ikona SF + krótka etykieta pod spodem.
/// Ostatnia komórka może być badge `+n` → tap otwiera pełną listę.
struct ParkEquipmentGridView: View {
    // MARK: Properties
    let equipments: [String]
    let onTapShowAll: () -> Void

    // Mapowanie nazwy sprzętu → (SF Symbol, krótkie PL)
    private let map: [String: (icon: String, label: String)] = [
        "Pull-up bar": ("figure.pullup", "drążek"),
        "Dip bar": ("flame", "poręcze"),
        "Monkey bars": ("rectangle.3.offgrid", "małpi"),
        "Rings": ("circle.grid.cross", "kółka"),
        "Push-up handles": ("hands.sparkles", "pompki"),
        "Climbing rope": ("figure.climbing", "lina"),
        "Box jump": ("square.fill", "box"),
        "Resistance bands": ("bolt", "taśmy"),
        "Parallel bars": ("rectangle.compress.vertical", "por."),
        "Tires": ("circle", "opona"),
        "Battle ropes": ("wave.3.forward", "lina"),
        "Sledge hammer": ("hammer", "młot"),
        "Kettlebell": ("dumbbell", "kettle"),
        "Medicine ball": ("circle.inset.filled", "piłka")
    ]

    // MARK: Body
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(displayedItems, id: \.self) { equipment in
                equipmentCell(for: equipment)
            }
            if overflowCount > 0 {
                overflowCell(count: overflowCount)
            }
        }
    }

    // 3 kolumny na iPhone, adaptacyjne – każda 60 pt.
    private var gridColumns: [GridItem] {
        Array(repeating: .init(.fixed(72), spacing: 12), count: 3)
    }

    // MARK: Data helpers
    private var displayedItems: [String] {
        Array(equipments.prefix(9))
    }

    private var overflowCount: Int {
        max(0, equipments.count - 9)
    }

    private func icon(for equipment: String) -> String {
        map[equipment]?.icon ?? "questionmark"
    }

    private func shortLabel(for equipment: String) -> String {
        map[equipment]?.label ?? equipment.split(separator: " ").first.map(String.init) ?? equipment
    }

    // MARK: Cells
    @ViewBuilder
    private func equipmentCell(for equipment: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.accent.opacity(0.9))
                    .frame(width: 48, height: 48)
                Image(systemName: icon(for: equipment))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            Text(shortLabel(for: equipment))
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .onTapGesture { onTapShowAll() }
    }

    private func overflowCell(count: Int) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .strokeBorder(Color.textPrimary.opacity(0.3), lineWidth: 1)
                    .background(Circle().fill(Color.componentBackground.opacity(0.2)))
                    .frame(width: 48, height: 48)
                Text("+\(count)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.textPrimary)
            }
            Text("więcej")
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .onTapGesture { onTapShowAll() }
    }
}

// MARK: - Preview
#Preview {
    ParkEquipmentGridView(
        equipments: [
            "Pull-up bar", "Dip bar", "Monkey bars", "Rings", "Push-up handles",
            "Climbing rope", "Box jump", "Resistance bands", "Parallel bars", "Tires",
            "Battle ropes", "Sledge hammer", "Kettlebell", "Medicine ball"
        ],
        onTapShowAll: {}
    )
    .padding()
    .preferredColorScheme(.dark)
} 
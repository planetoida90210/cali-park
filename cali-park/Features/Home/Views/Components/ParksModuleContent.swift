import SwiftUI

// MARK: - Parks Module

struct ParksModuleContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Pogoda
                VStack(alignment: .leading, spacing: 4) {
                    Text("Warszawa")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                    
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(Color.yellow)
                        
                        Text("22°C")
                            .font(.title3.bold())
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                
                Spacer()
                
                // Najbliższe parki
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Najbliższy park")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                    
                    Text("Park Skaryszewski (1,2 km)")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textPrimary)
                }
            }
            
            // Lista pobliskich parków
            VStack(spacing: 12) {
                parkRow(name: "Park Skaryszewski", distance: "1,2 km", busy: "Średnio zatłoczony")
                parkRow(name: "Park Praski", distance: "2,5 km", busy: "Mało zatłoczony")
            }
            
            Button(action: {
                // Akcja otworzenia mapy
            }) {
                Text("Pokaż na mapie")
                    .font(.buttonMedium)
                    .foregroundStyle(Color.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.glassBackground)
                    .clipShape(.rect(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accent, lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(Color.componentBackground)
        .clipShape(.rect(cornerRadius: 12))
    }
    
    private func parkRow(name: String, distance: String, busy: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
                
                Text(busy)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Spacer()
            
            Text(distance)
                .font(.bodyMedium)
                .foregroundStyle(Color.accent)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ParksModuleContent()
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 
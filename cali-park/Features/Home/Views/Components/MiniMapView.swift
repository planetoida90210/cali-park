import SwiftUI
import MapKit

struct MiniMapView: View {
    var nearbySpots: [CalisthenicsSpot]
    @State private var selectedSpot: CalisthenicsSpot?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Mapa
            ZStack(alignment: .bottom) {
                Map {
                    ForEach(nearbySpots, id: \.id) { spot in
                        Marker(spot.name, coordinate: CLLocationCoordinate2D(
                            latitude: spot.latitude,
                            longitude: spot.longitude
                        ))
                        .tint(.yellow)
                    }
                }
                .frame(height: 180)
                .cornerRadius(12)
                .disabled(true) // blokowanie interakcji z mapą, klikniecie w przycisk nawiguj będzie otwierać pełną mapę
                
                // Gradient overlay dla lepszej czytelności
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.4)
                    ]),
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 80)
                .cornerRadius(12)
            }
            
            if let closest = nearbySpots.first {
                // Główny CTA - nawigacja do najbliższego parku
                Button(action: {
                    // Akcja nawigowania do parku
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(closest.name)
                                .font(.bodyLarge)
                                .foregroundColor(.textPrimary)
                            
                            Text("\(String(format: "%.1f", closest.distance)) km • \(closest.difficultyLevel.rawValue)")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text("Nawiguj")
                            .font(.buttonMedium)
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accent)
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.componentBackground)
                    .cornerRadius(12)
                }
            }
            
            // Zobacz wszystkie - Drugie CTA
            Button(action: {
                // Akcja pokazania wszystkich parków
            }) {
                HStack {
                    Text("Zobacz wszystkie parki")
                        .font(.bodyMedium)
                        .foregroundColor(.accent)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.accent)
                }
                .padding()
                .background(Color.componentBackground)
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    MiniMapView(nearbySpots: MockData.nearbySpots)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 
import SwiftUI
import MapKit

struct MiniMapView: View {
    var nearbySpots: [CalisthenicsSpot]
    @State private var selectedSpot: CalisthenicsSpot?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Najbliższe parki kalisteniki")
                .font(.title3)
                .foregroundColor(.textPrimary)
            
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
            
            // Lista najbliższych parków
            ForEach(nearbySpots.prefix(2), id: \.id) { spot in
                Button(action: {
                    selectedSpot = spot
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(spot.name)
                                .font(.bodyLarge)
                                .foregroundColor(.textPrimary)
                            
                            HStack {
                                Text("\(String(format: "%.1f", spot.distance)) km")
                                    .font(.bodySmall)
                                    .foregroundColor(.accent)
                                
                                Text("•")
                                    .foregroundColor(.textSecondary)
                                
                                Text(spot.difficultyLevel.rawValue)
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Przycisk nawiguj
                        Button(action: {
                            // Akcja nawigowania do parku
                        }) {
                            Text("Nawiguj")
                                .font(.bodyMedium)
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accent)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.componentBackground)
                    .cornerRadius(12)
                }
            }
            
            // Przycisk "Zobacz wszystkie"
            if nearbySpots.count > 2 {
                Button(action: {
                    // Akcja pokazania wszystkich parków
                }) {
                    HStack {
                        Text("Zobacz wszystkie")
                            .font(.bodyMedium)
                            .foregroundColor(.accent)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.accent)
                    }
                    .padding()
                    .background(Color.componentBackground)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    MiniMapView(nearbySpots: MockData.nearbySpots)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 
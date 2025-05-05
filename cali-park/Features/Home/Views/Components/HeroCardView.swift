import SwiftUI

struct HeroCardView: View {
    let name: String
    let weeklyReps: Int
    let progress: Double
    
    var body: some View {
        HStack(alignment: .top) {
            // Left content: Greeting + Weekly Reps
            VStack(alignment: .leading, spacing: 4) {
                Text("Siema, \(name)!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("\(weeklyReps) podciągnięć w tym tygodniu")
                    .font(.bodyLarge)
                    .foregroundColor(.accent)
            }
            
            Spacer()
            
            // Right content: Progress Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(lineWidth: 6)
                    .opacity(0.3)
                    .foregroundColor(.componentBackground)
                
                // Progress ring
                Circle()
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.accent)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: progress)
                
                // Percentage text
                Text("\(Int(progress * 100))%")
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.accent)
            }
            .frame(width: 56, height: 56)
        }
        .padding(16)
        .background(Color.black)
        .cornerRadius(12)
        .edgesIgnoringSafeArea(.top)
    }
}

struct HeroCardView_Previews: PreviewProvider {
    static var previews: some View {
        HeroCardView(
            name: "Michał",
            weeklyReps: 57,
            progress: 0.75
        )
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
} 
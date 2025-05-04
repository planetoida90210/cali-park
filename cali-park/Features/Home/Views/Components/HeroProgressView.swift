import SwiftUI

struct HeroProgressView: View {
    var userProfile: UserProfile
    
    var body: some View {
        VStack(spacing: 20) {
            // Hero text
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Siema, \(userProfile.name)!")
                        .font(.title1)
                        .foregroundColor(.textPrimary)
                    
                    Text("\(userProfile.weeklyPullUps) podciągnięcia w tym tygodniu")
                        .font(.title3)
                        .foregroundColor(.accent)
                }
                
                Spacer()
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.componentBackground, lineWidth: 10)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: userProfile.weeklyProgress)
                        .stroke(Color.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(userProfile.weeklyProgress * 100))%")
                        .font(.bodyLarge)
                        .bold()
                        .foregroundColor(.textPrimary)
                }
            }
            .padding(.horizontal)
            
            // Call to Action button
            Button(action: {
                // Akcja rozpoczęcia treningu
            }) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.bodyLarge)
                    
                    Text("Start treningu")
                        .font(.buttonLarge)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
        }
        .padding(.vertical)
        .cardStyle()
    }
}

#Preview {
    HeroProgressView(userProfile: MockData.userProfile)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
} 
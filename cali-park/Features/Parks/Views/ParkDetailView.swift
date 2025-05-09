import SwiftUI
import Combine
import MapKit

// MARK: - ParkDetailView
struct ParkDetailView: View {
    // Park przekazywany z listy
    let park: Park
    // Premium status – w przyszłości pobierzemy z konta użytkownika
    var isPremiumUser: Bool = false

    @EnvironmentObject private var parksVM: ParksViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showReportSheet = false
    @State private var showAddLogSheet = false
    @State private var showEquipmentSheet = false

    // Action Row View-Model
    @StateObject private var actionVM = ParkActionRowViewModel()

    // Shared events & reviews ViewModels injected down the hierarchy
    @StateObject private var eventsVM: ParkEventsViewModel
    @StateObject private var reviewsVM: ParkReviewsViewModel

    // Global quick-join state – drives toast visibility
    @State private var joinedEventID: UUID?

    // Review sheet states
    @State private var showAddEditReviewSheet = false
    @State private var showAllReviewsSheet = false

    // Custom init to create shared Events ViewModel
    init(park: Park, isPremiumUser: Bool = false) {
        self.park = park
        self.isPremiumUser = isPremiumUser
        _eventsVM = StateObject(wrappedValue: ParkEventsViewModel(parkID: park.id))
        _reviewsVM = StateObject(wrappedValue: ParkReviewsViewModel(parkID: park.id))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ParkHeroHeaderView(park: park, isPremiumUser: isPremiumUser)
                    ParkStatsStripView(park: park)
                    ParkActionRowView(viewModel: actionVM)
                    equipmentSection
                    ParkEventsSectionView(park: park, isPremiumUser: isPremiumUser, onJoin: joinEvent)
                        .environmentObject(eventsVM)
                    ParkReviewsSectionView(
                        viewModel: reviewsVM,
                        onAddEdit: { showAddEditReviewSheet = true },
                        onShowAll: { showAllReviewsSheet = true }
                    )
                }
                .padding(16)
                .padding(.bottom, 140) // extra space for FAB
                // Listen for row offset updates
                .onPreferenceChange(ActionRowOffsetKey.self) { value in
                    actionVM.updateRowOffset(value)
                }
            }
            // Floating Action Button
            if actionVM.showFAB {
                ParkActionFAB(viewModel: actionVM)
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .background(Color.appBackground)
        // Global toast overlay driven by joinedEventID
        .overlay {
            if joinedEventID != nil {
                QuickJoinToast()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation { joinedEventID = nil }
                        }
                    }
            }
        }
        // Listen for last joined updates from VM to trigger toast
        .onReceive(eventsVM.$lastJoined.compactMap { $0 }) { event in
            withAnimation { joinedEventID = event.id }
        }
        .navigationTitle(park.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Zamknij") { dismiss() } } }
        .sheet(isPresented: $showReportSheet) { ReportParkView(park: park) }
        .sheet(isPresented: $showAddLogSheet) { QuickLogPlaceholder() }
        .sheet(isPresented: $showEquipmentSheet) { EquipmentSheetView(equipments: park.equipments) }
        .sheet(isPresented: $showAddEditReviewSheet) { AddReviewSheetView(viewModel: reviewsVM) }
        .sheet(isPresented: $showAllReviewsSheet) { ReviewsListSheetView(viewModel: reviewsVM) }
        .onAppear {
            // Inject actions into VM
            actionVM.navigateToPark = openInMaps
            actionVM.addWorkoutLog = { showAddLogSheet = true }
            actionVM.reportProblem = { showReportSheet = true }
        }
    }

    // MARK: - Sections
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wyposażenie")
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
            if park.equipments.isEmpty {
                Text("Brak danych")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            } else {
                ParkEquipmentRowView(
                    equipments: park.equipments,
                    onTapShowAll: { showEquipmentSheet = true }
                )
            }
        }
    }

    // MARK: - Helpers
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: park.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = park.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    // MARK: - Join handler
    private func joinEvent(_ event: ParkEvent) {
        Task { await eventsVM.join(event) }
    }

    // MARK: - Toast
    private struct QuickJoinToast: View {
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.black)
                Text("Dołączono do wydarzenia")
                    .foregroundColor(.black)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.accent)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Quick Log placeholder
private struct QuickLogPlaceholder: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Text("Quick workout log w budowie ✌️")
                .padding()
                .navigationTitle("Dodaj log")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Zamknij") { dismiss() } } }
        }
    }
}

// MARK: - Report View (mock)
private struct ReportParkView: View {
    let park: Park
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Text("Raportowanie jeszcze w przygotowaniu ✌️")
                .padding()
                .navigationTitle("Zgłoś park")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Zamknij") { dismiss() } } }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ParkDetailView(park: .mock.first!)
            .environmentObject(ParksViewModel())
    }
    .preferredColorScheme(.dark)
} 
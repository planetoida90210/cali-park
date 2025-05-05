import SwiftUI

struct ParksView: View {
    // MARK: - State & ViewModel
    @StateObject private var viewModel = ParksViewModel()
    @State private var showMapSheet: Bool = false
    @FocusState private var searchFocused: Bool
    @State private var selectedPark: Park?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Global background matching HomeView
            Color.appBackground
                .edgesIgnoringSafeArea(.all)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        searchBar
                        tabBar
                        parksList
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                    }
                    // Background handled by root ZStack
                }
            }
            .scrollDismissesKeyboard(.interactively)
            mapButton
        }
        .sheet(isPresented: $showMapSheet) {
            MapSheetView(viewModel: viewModel)
                .presentationDetents([.fraction(0.5), .large])
        }
        .navigationTitle("Siłownie")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture { hideKeyboard() }
        .task {
            // Auto-focus search bar shortly after view appears
            try? await Task.sleep(for: .milliseconds(200))
            searchFocused = true
        }
        .navigationDestination(item: $selectedPark) { park in
            ParkDetailView(park: park)
                .environmentObject(viewModel)
        }
    }

    // MARK: - Subviews
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.accent)

            TextField("Szukaj nazwy lub miasta", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .submitLabel(.search)
                .foregroundColor(.textPrimary)
                .onChange(of: viewModel.searchText) { old, new in
                    // Trim spaces so clear button rzeczywiście znika
                    viewModel.searchText = new.trimmingCharacters(in: .whitespaces)
                }

            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textSecondary)
                }
            }

            Button {
                // TODO: filter action
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .foregroundColor(.accent)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.componentBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accent.opacity(searchFocused ? 1 : 0.4), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }

    private var tabBar: some View {
        HStack(spacing: 24) {
            ForEach(ParksViewModel.Tab.allCases) { tab in
                VStack(spacing: 4) {
                    Text(tab.rawValue)
                        .font(.bodyMedium)
                        .foregroundColor(viewModel.selectedTab == tab ? .accent : .textSecondary)
                    if viewModel.selectedTab == tab {
                        Capsule()
                            .fill(Color.accent)
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "tabBar", in: namespace)
                    } else {
                        Capsule()
                            .fill(Color.clear)
                            .frame(height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut) { viewModel.selectedTab = tab }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    @Namespace var namespace

    private var parksList: some View {
        Group {
            if viewModel.displayedParks.isEmpty {
                emptyState
                    .padding(.top, 60)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.displayedParks) { park in
                        ParkCardView(park: park)
                            .environmentObject(viewModel)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                navigateToDetail(park)
                            }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.selectedTab == .favorites ? "heart" : "mappin.slash")
                .font(.system(size: 32))
                .foregroundColor(.accent.opacity(0.8))

            Text(viewModel.selectedTab == .favorites ? "Brak ulubionych siłowni" : "Brak wyników")
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)

            if viewModel.selectedTab == .favorites {
                Text("Polub swoją pierwszą siłownię, klikając w serduszko przy kafelku.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Spróbuj zmienić filtry lub wyszukaj inną lokalizację.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var mapButton: some View {
        Button(action: { showMapSheet = true }) {
            Image(systemName: "map.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color.componentBackground)
                .padding(18)
                .background(Color.accent)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(20)
    }

    private func navigateToDetail(_ park: Park) {
        selectedPark = park
    }
}

// MARK: - Preview
struct ParksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ParksView()
        }
    }
} 
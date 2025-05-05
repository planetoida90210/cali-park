import SwiftUI

struct ParksView: View {
    // MARK: - State & ViewModel
    @StateObject private var viewModel = ParksViewModel()
    @State private var showMapSheet: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        searchBar
                        tabBar
                        parksList
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                    }
                }
            }
            mapButton
        }
        .sheet(isPresented: $showMapSheet) {
            MapSheetView(viewModel: viewModel)
                .presentationDetents([.fraction(0.5), .large])
        }
        .navigationTitle("Siłownie")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
            TextField("Szukaj nazwy lub miasta", text: $viewModel.searchText)
                .textFieldStyle(.plain)
            Button {
                // TODO: filter action
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .foregroundColor(.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.glassBackground)
        .cornerRadius(12)
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
        LazyVStack(spacing: 12) {
            ForEach(viewModel.displayedParks) { park in
                ParkCardView(park: park)
            }
        }
    }

    private var mapButton: some View {
        Button(action: { showMapSheet = true }) {
            Text("🗺️")
                .font(.title2)
                .padding(12)
                .background(Color.accent)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .padding(20)
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
//
//  ContentView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 1/29/25.
//

import MapKit
import PhotosUI
import SwiftUI

/// The main view displaying a Map and handling sheet presentations & navigation.
/// Ensures that `SampleView` reappears when returning to this screen.
struct ContentView: View {
    // MARK: Properties

    /// Controls when the SampleView sheet is shown.
    @State private var showExampleSheet = false

    /// Controls when the OpenAppView sheet is shown.
    @State private var showOpenAppSheet = false

    /// Controls navigation to the NoteView.
    @State private var navigateToNote = false
    
    @State private var navigateToPetal = false

    /// Tracks if ExampleSheet was dismissed when navigating away.
    @State private var wasExampleSheetDismissed = false

    /// Tracks if walking routes should be shown.
    @State private var showWalkingRoutes = true

    /// Tracks if running routes should be shown.
    @State private var showRunningRoutes = true

    /// Tracks if cycling routes should be shown
    @State private var showCyclingRoutes = true

    /// Track the user's selected time interval.
    @State private var selectedSyncInterval: TimeInterval = 3600

    /// The object that interfaces with HealthKit to fetch route data.
    @ObservedObject var healthKitManager = HealthKitManager()

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                Map {
                    // 🟦 Walking Routes
                    if showWalkingRoutes {
                        ForEach(healthKitManager.walkingRoutes, id: \.self) { route in
                            let coordinates = route.map(\.coordinate)
                            let polyline = MKPolyline(
                                coordinates: coordinates,
                                count: coordinates.count
                            )

                            withAnimation {
                                MapPolyline(polyline)
                                    .stroke(Color.blue, lineWidth: 3)
                            }
                        }
                    }

                    // 🟥 Running Routes
                    if showRunningRoutes {
                        ForEach(healthKitManager.runningRoutes, id: \.self) { route in
                            let coordinates = route.map(\.coordinate)
                            let polyline = MKPolyline(
                                coordinates: coordinates,
                                count: coordinates.count
                            )

                            withAnimation {
                                MapPolyline(polyline)
                                    .stroke(Color.red, lineWidth: 3)
                            }
                        }
                    }

                    // 🟩 Cycling Routes
                    if showCyclingRoutes {
                        ForEach(healthKitManager.cyclingRoutes, id: \.self) { route in
                            let coordinates = route.map(\.coordinate)
                            let polyline = MKPolyline(
                                coordinates: coordinates,
                                count: coordinates.count
                            )

                            withAnimation {
                                MapPolyline(polyline)
                                    .stroke(Color.green, lineWidth: 3)
                            }
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)

                // Hidden navigation link for programmatic navigation.
                NavigationLink(
                    destination: OpenAppView(),
                    isActive: $navigateToNote
                ) {
                    EmptyView()
                }
                
                NavigationLink(
                    destination: PetalAssistantView(),
                    isActive: $navigateToPetal
                ) {
                    EmptyView()
                }
            }
            // Primary sheet – SampleView.
            .sheet(isPresented: $showExampleSheet) {
                SampleView(
                    showWalkingRoutes: $showWalkingRoutes,
                    showRunningRoutes: $showRunningRoutes,
                    showCyclingRoutes: $showCyclingRoutes,
                    onOpenAppTap: {
                        // Dismiss SampleView and present OpenAppView.
                        showExampleSheet = false
                        wasExampleSheetDismissed = true
                        DispatchQueue.main.async {
                            showOpenAppSheet = true
                        }
                    },
                    onNoteTap: {
                        // Dismiss SampleView and navigate to NoteView.
                        showExampleSheet = false
                        wasExampleSheetDismissed = true
                        DispatchQueue.main.async {
                            navigateToNote = true
                        }
                    },
                    onPetalTap: {
                        showExampleSheet = false
                        wasExampleSheetDismissed = true
                        Task { @MainActor in
                            navigateToPetal = true
                        }
                    }
                )
                .presentationDetents([
                    .custom(CompactDetent.self),
                    .medium,
                    .custom(OneSmallThanMaxDetent.self)
                ])
                .presentationCornerRadius(30)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
            }
            // Secondary sheet – OpenAppView.
            .sheet(isPresented: $showOpenAppSheet, onDismiss: {
                showExampleSheet = true
            }) {
                OpenAppView()
            }
            .onAppear {
                // Show ExampleSheet again if returning to this view.
                // CoreDataManager.shared.clearAllData()

                showExampleSheet = true
                Task(priority: .high) {
                    await healthKitManager.requestHKPermissions()
                }
                healthKitManager.loadRoutes()

                DispatchQueue.main.asyncAfter(deadline: .now() + 10) { // Wait 5s for routes to load.
                    print("📍 Walking Routes: \(healthKitManager.walkingRoutes.count)")
                    print("📍 Running Routes: \(healthKitManager.runningRoutes.count)")
                    print("📍 Cycling Routes: \(healthKitManager.cyclingRoutes.count)")
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - SampleView (Main Bottom Sheet)

/// A bottom sheet view that provides several shortcuts and actions.
struct SampleView: View {

    /// Track the user's selected time interval.
    @State private var selectedSyncInterval: TimeInterval = 3600

    /// The search text.
    @State private var searchText: String = ""

    /// The object that interfaces with HealthKit to fetch route data.
    @ObservedObject var healthKitManager = HealthKitManager()

    /// Bindings that toggle whether walking routes should be shown.
    @Binding var showWalkingRoutes: Bool

    /// Bindings that toggle whether running routes should be shown.
    @Binding var showRunningRoutes: Bool

    /// Bindings that toggle whether cycling routes should be shown.
    @Binding var showCyclingRoutes: Bool

    let onOpenAppTap: () -> Void
    let onNoteTap: () -> Void
    let onPetalTap: () -> Void

    let categories = [
        ("Scripting", "wand.and.stars"),
        ("Controls", "slider.horizontal.3"),
        ("Device", "iphone.gen3"),
        ("More", "ellipsis")
    ]

    let sampleData = ["Running Route", "Walking Route", "Cycling Route"] // Placeholder data

    var filteredItems: [String] {
        searchText.isEmpty ? sampleData : sampleData.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ScrollView {
            VStack {
                SearchBarView(searchText: $searchText)

                VStack {
                    Text("Sync Frequency")
                        .font(.headline)

                    Picker("Sync Interval", selection: $selectedSyncInterval) {
                        Text("Every 30 min").tag(30.0)
                        Text("Every Hour").tag(60.0)
                        Text("Every 2 Hours").tag(120.0)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    Button("Sync Now") {
                        healthKitManager.syncData(interval: selectedSyncInterval)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }

                HStack(spacing: 10) {
                    ToggleButton(title: "Running", color: .red, isOn: $showRunningRoutes)
                    ToggleButton(title: "Walking", color: .blue, isOn: $showWalkingRoutes)
                    ToggleButton(title: "Cycling", color: .green, isOn: $showCyclingRoutes)
                }
                .padding()
            }

            // Horizontal scroll categories.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories, id: \.0) { category in
                        CategoryButton(title: category.0, icon: category.1)
                    }
                }
                .padding(.horizontal)
            }

            VStack {
                // List of Filtered Items
                if !filteredItems.isEmpty {
                    ForEach(filteredItems, id: \.self) { item in
                        Text(item)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray5)))
                            .padding(.horizontal)
                    }
                } else {
                    Text("No results found")
                        .foregroundColor(.gray)
                        .padding()
                }
            }

            // Shortcuts Grid.
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ShortcutButton(
                    title: "Open App...",
                    icon: "square.dashed",
                    gradient: Gradient(colors: [.blue, .cyan]),
                    action: onOpenAppTap
                )
                ShortcutButton(
                    title: "Call Favorites",
                    icon: "phone.fill",
                    gradient: Gradient(colors: [.green, .mint]),
                    action: onPetalTap
                )
                ShortcutButton(
                    title: "Recently Played",
                    icon: "music.note",
                    gradient: Gradient(colors: [.red, .orange])
                )
                ShortcutButton(
                    title: "Set Timer",
                    icon: "timer",
                    gradient: Gradient(colors: [.yellow, .orange])
                )
                ShortcutButton(
                    title: "New Note",
                    icon: "note.text",
                    gradient: Gradient(colors: [.orange, .yellow]),
                    action: onNoteTap
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: Subviews

    /// The search bar that in the future will allow users to filter different data values.
    /// Currently it is a static UI element
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.gray.opacity(0.8))
            Text("Search")
                .foregroundStyle(.gray.opacity(0.8))
            Spacer()
        }
        .padding(.all, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 15)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

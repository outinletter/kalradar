import Foundation
import SwiftUI

@MainActor final class RadarStore: ObservableObject {
    enum Mode: String, CaseIterable { case demo, live }
    @Published private(set) var mode: Mode = .live
    @Published private(set) var flights: [Flight] = []
    @Published var selectedID: String? = nil
    @Published var search = ""
    @Published private(set) var isLoading = false
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var error: String?
    @Published private(set) var providerName = "무료 공개 ADS-B"
    @Published private(set) var providerNotice: String?
    @Published private(set) var scopeName = "전 세계 · 아직 조회 전"
    @Published var settingsNotice: String?
    private var refreshTask: Task<Void, Never>?
    private var generation = 0
    var selected: Flight? { flights.first { $0.id == selectedID } }
    var filteredFlights: [Flight] { guard let query = search.nonEmpty else { return flights }; return flights.filter { $0.searchableText.localizedCaseInsensitiveContains(query) } }
    func refreshIfNeeded() {
        guard mode == .live, !isLoading else { return }
        if let lastUpdated, Date().timeIntervalSince(lastUpdated) < SharedRadar.refreshInterval { return }
        refresh()
    }
    func setMode(_ newMode: Mode) {
        guard mode != newMode else { return }
        generation += 1; refreshTask?.cancel(); refreshTask = nil; isLoading = false
        mode = newMode; error = nil; lastUpdated = nil; search = ""
        providerName = "무료 공개 ADS-B"; providerNotice = nil; scopeName = "전 세계 · 아직 조회 전"
        flights = newMode == .demo ? KoreanAirFilter.apply(DemoFlights.all) : []
        selectedID = newMode == .demo ? "demo-1" : nil
        if newMode == .live { refreshIfNeeded() }
    }
    func loadSelectedRoute() async {
        guard mode == .live, let id = selectedID, let flight = selected, let callsign = flight.callsign?.nonEmpty else { return }
        let current = generation
        guard let route = await RouteClient.shared.route(callsign: callsign), !Task.isCancelled, current == generation, mode == .live,
              let index = flights.firstIndex(where: { $0.id == id && $0.callsign == flight.callsign }) else { return }
        flights[index].origin = route.origin; flights[index].destination = route.destination
        flights[index].number = route.number
    }
    func refresh() {
        guard !isLoading else { return }
        if mode == .demo { flights = KoreanAirFilter.apply(DemoFlights.all); return }
        isLoading = true; error = nil
        let current = generation
        refreshTask = Task { [weak self] in
            do {
                let snapshot = try await PublicADSBClient.shared.positions()
                let values = snapshot.flights
                guard let self, !Task.isCancelled, current == self.generation else { return }
                self.flights = values; self.lastUpdated = Date(); self.providerName = snapshot.provider; self.providerNotice = snapshot.notice; self.scopeName = snapshot.scope
                if !values.contains(where: { $0.id == self.selectedID }) { self.selectedID = values.first?.id }
                self.isLoading = false
                await self.loadSelectedRoute()
            } catch {
                guard let self, !Task.isCancelled, current == self.generation else { return }
                self.error = error.localizedDescription; self.isLoading = false
                // Keep last successful response, visibly marked as stale on failure.
            }
        }
    }
}

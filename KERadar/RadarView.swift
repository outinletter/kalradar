import SwiftUI
import MapKit

 enum Theme {
    static let navy = Color(red: 0.95, green: 0.97, blue: 0.98)
    static let panel = Color.white
    static let mint = Color(red: 0.0, green: 0.40, blue: 0.34)
    static let muted = Color(red: 0.34, green: 0.41, blue: 0.48)
 }

struct RadarView: View {
    @EnvironmentObject private var store: RadarStore
    @State private var camera: MapCameraPosition = .region(.init(center: .init(latitude: 35.8, longitude: 129.5), span: .init(latitudeDelta: 17, longitudeDelta: 22)))
    @State private var showingSettings = false
    @State private var showingList = false
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                header
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        badge(store.mode == .demo ? "데모 · 가상 항공편" : "\(store.providerName) · 무료", icon: store.mode == .demo ? "sparkles" : "antenna.radiowaves.left.and.right", color: store.mode == .demo ? .orange : Theme.mint)
                        badge("KAL 호출부호만", icon: "checkmark.shield", color: Theme.mint)
                        badge("\(store.flights.count)대 표시", icon: "airplane", color: .primary)
                    }.padding(.horizontal, 18).padding(.bottom, 12)
                }
                if let notice = store.providerNotice { Text(notice).font(.caption2).foregroundStyle(.orange).padding(8) }
                if store.showingSaved { Text("저장 항적 · 실시간 아님 · \(store.savedAt?.formatted() ?? "저장 시각 미상")").font(.caption).foregroundStyle(.orange).padding(8) }
                if let error = store.error {
                    Label(error + (store.flights.isEmpty ? "" : " 이전 응답을 표시합니다."), systemImage: "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(.orange).padding(12).frame(maxWidth: .infinity, alignment: .leading).background(.orange.opacity(0.10))
                }
                ZStack(alignment: .topLeading) {
                    radarMap
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button { withAnimation { camera = .automatic } } label: { Image(systemName: "scope").font(.title3).frame(width: 44, height: 44).background(Theme.panel, in: Circle()) }
                                .accessibilityLabel("전체 항공기 보기")
                        }
                    }.padding(14)
                }
                .frame(height: max(0, geo.size.width - 24) * 3 / 4)
                .clipShape(RoundedRectangle(cornerRadius: 22)).padding(.horizontal, 12)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            TextField("편명 검색 · KE123 / KAL123", text: $store.search)
                                .textInputAutocapitalization(.characters).autocorrectionDisabled()
                                .padding(10).background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
                                .onSubmit { showingList = true }
                                .accessibilityLabel("편명 검색")
                            Button { showingList = true } label: { Text("전체 목록").font(.caption.weight(.semibold)); Image(systemName: "arrow.up.right").font(.caption) }.accessibilityLabel("전체 항공편 목록")
                        }
                        if !store.search.isEmpty { ForEach(store.filteredFlights.prefix(8)) { flight in Button("\(flight.label) · \(flight.route)") { store.selectedID = flight.id }.font(.caption) } }
                        if let flight = store.selected {
                            FlightDetailCard(flight: flight, demo: store.mode == .demo)
                        } else {
                            VStack(spacing: 9) {
                                Image(systemName: store.mode == .live ? "antenna.radiowaves.left.and.right" : "airplane").font(.title).foregroundStyle(Theme.mint)
                                Text(store.mode == .live && store.lastUpdated == nil ? store.isLoading ? "운항 정보를 불러오는 중입니다" : "운항 정보를 불러오지 못했습니다" : "표시할 운항편이 없습니다").font(.headline)
                                Text(store.mode == .live && store.lastUpdated == nil ? "연결 상태를 확인하고 새로고침으로 다시 조회할 수 있습니다." : "필터를 통과한 유효 위치의 항공편만 표시합니다.").font(.caption).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                            }.padding(22).frame(maxWidth: .infinity).background(Theme.panel, in: RoundedRectangle(cornerRadius: 18))
                        }
                        if store.mode == .demo { Text("DEMO DATA · 실제 운항 상태가 아닙니다").font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.5).foregroundStyle(.orange) }
                        else { Text("\(freshness) · \(store.providerName) · \(store.scopeName)").font(.caption2).foregroundStyle(Theme.muted) }
                    }.padding(18)
                }
            }.background(Theme.navy)
        }
        .task(id: store.selectedID) { await store.loadSelectedRoute() }
        .sheet(isPresented: $showingSettings) { SettingsView().environmentObject(store) }
        .sheet(isPresented: $showingList) { FlightListView { flight in store.selectedID = flight.id; withAnimation { camera = .region(.init(center: flight.coordinate, span: .init(latitudeDelta: 7, longitudeDelta: 9))) }; showingList = false }.environmentObject(store) }
    }
    private var freshness: String {
        guard let updated = store.lastUpdated else { return "조회 중" }
        return "최근 조회 \(updated.formatted(date: .omitted, time: .standard))"
    }
    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "airplane.circle.fill").font(.system(size: 30)).foregroundStyle(Theme.mint)
            VStack(alignment: .leading, spacing: 2) {
                Text(SharedRadar.appName).font(.system(size: 23, weight: .bold, design: .rounded))
                Text(SharedRadar.subtitle).font(.system(size: 10, weight: .medium)).foregroundStyle(Theme.muted)
            }
            Spacer()
            Button { store.refresh() } label: {
                if store.isLoading { ProgressView().frame(width: 40, height: 40) }
                else { Image(systemName: "arrow.clockwise").font(.system(size: 18, weight: .semibold)).frame(width: 40, height: 40) }
            }.disabled(store.isLoading).accessibilityLabel("수동 새로고침")
            Button { showingSettings = true } label: { Image(systemName: "slider.horizontal.3").font(.system(size: 19)).frame(width: 40, height: 40) }.accessibilityLabel("설정")
        }.padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 16)
    }
    private var radarMap: some View {
        Map(position: $camera, selection: $store.selectedID) {
            ForEach(store.flights) { flight in
                Annotation(flight.label, coordinate: flight.coordinate, anchor: .center) {
                    Button { store.selectedID = flight.id } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "airplane").font(.system(size: store.selectedID == flight.id ? 27 : 21, weight: .bold))
                                .rotationEffect(.degrees((flight.heading ?? 0) - 90))
                                .foregroundStyle(store.selectedID == flight.id ? Theme.navy : Theme.mint)
                                .frame(width: 44, height: 44).background(store.selectedID == flight.id ? Theme.mint : Theme.navy.opacity(0.85), in: Circle())
                                .overlay(Circle().stroke(Theme.mint.opacity(0.6), lineWidth: 1)).shadow(color: Theme.mint.opacity(0.25), radius: 8)
                            Text("\(flight.label) · \(flight.route)").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.primary).padding(.horizontal, 5).padding(.vertical, 3).background(Theme.navy.opacity(0.9), in: Capsule())
                        }
                    }.buttonStyle(.plain).accessibilityLabel("\(flight.label), \(flight.route)")
                }.tag(flight.id)
            }
        }.mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll, showsTraffic: false))
        .mapControlVisibility(.hidden)
    }
    private func badge(_ text: String, icon: String, color: Color) -> some View { Label(text, systemImage: icon).font(.system(size: 10, weight: .semibold)).foregroundStyle(color).padding(.horizontal, 10).padding(.vertical, 7).background(color.opacity(0.09), in: Capsule()) }
}

struct FlightDetailCard: View {
    let flight: Flight
    let demo: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(flight.label).font(.system(size: 24, weight: .bold, design: .rounded))
                    Text(flight.route).font(.subheadline).foregroundStyle(Theme.mint)
                    Text("\(flight.callsign ?? "호출부호 미상") · \(flight.aircraft ?? "기종 미상")").font(.caption).foregroundStyle(Theme.muted)
                }
                Spacer()
                Text(demo ? "가상 운항" : "최근 위치").font(.caption2.weight(.semibold)).foregroundStyle(demo ? .orange : Theme.mint).padding(7).background((demo ? Color.orange : Theme.mint).opacity(0.12), in: Capsule())
            }
            HStack(alignment: .center) {
                airport(flight.origin ?? "미상", label: "출발")
                Spacer()
                VStack(spacing: 4) { Image(systemName: "airplane").font(.title3).foregroundStyle(Theme.mint); Capsule().fill(Theme.mint.opacity(0.3)).frame(width: 78, height: 2) }
                Spacer()
                airport(flight.destination ?? "미상", label: "도착")
            }
            Divider().overlay(Theme.muted.opacity(0.2))
            HStack {
                metric("고도", value: number(flight.altitude), unit: "ft", icon: "arrow.up")
                Spacer(); metric("지상 속도", value: number(flight.speed), unit: "kt", icon: "speedometer")
                Spacer(); metric("방향", value: number(flight.heading), unit: "°", icon: "location.north")
            }
            HStack { Text(flight.registration ?? "등록번호 미상"); Spacer(); Text(flight.isCallsignFallback ? "KAL 호출부호 추정" : "운항사 KAL") }.font(.caption2).foregroundStyle(Theme.muted)
            if !demo && flight.origin != nil { Text("ADSBDB 등록 경로 · 실제 운항과 다를 수 있음").font(.caption2).foregroundStyle(Theme.muted) }
            if !demo { TimelineView(.periodic(from: .now, by: 30)) { _ in Text("\(flight.observedUTC) · \(flight.observationStatus)").font(.caption).foregroundStyle(Theme.muted) } }
            ShareLink(item: flight.briefing) { Label("항공편 요약 공유", systemImage: "square.and.arrow.up") }.font(.caption)
            if !demo { Text(flight.timestamp.map { "위치 관측 \($0.formatted(date: .abbreviated, time: .standard)) · \(flight.source ?? "출처 미상")" } ?? "관측 시각 미상 · 최신성 보장 안 됨").font(.caption2).foregroundStyle(Theme.muted) }
        }.padding(18).background(Theme.panel, in: RoundedRectangle(cornerRadius: 20)).overlay(RoundedRectangle(cornerRadius: 20).stroke(.black.opacity(0.08)))
    }
    private func number(_ value: Double?) -> String { value.map { $0.formatted(.number.precision(.fractionLength(0))) } ?? "--" }
    private func airport(_ code: String, label: String) -> some View { VStack(alignment: .leading, spacing: 3) { Text(label).font(.caption2).foregroundStyle(Theme.muted); Text(code).font(.system(size: 27, weight: .bold, design: .monospaced)) } }
    private func metric(_ label: String, value: String, unit: String, icon: String) -> some View { VStack(alignment: .leading, spacing: 6) { Label(label, systemImage: icon).font(.system(size: 10)).foregroundStyle(Theme.muted); HStack(alignment: .firstTextBaseline, spacing: 3) { Text(value).font(.system(size: 18, weight: .semibold, design: .rounded)); Text(unit).font(.caption2).foregroundStyle(Theme.muted) } } }
}

struct FlightListView: View {
    @EnvironmentObject private var store: RadarStore
    let select: (Flight) -> Void
    var body: some View {
        NavigationStack {
            List {
                Section { Text(store.mode == .demo ? "데모 · 모든 편명과 위치는 가상입니다" : "KAL 호출부호 추정 · 마지막 수동 조회 결과").font(.caption).foregroundStyle(store.mode == .demo ? .orange : Theme.mint) }
                Section("\(store.filteredFlights.count)개 항공편") {
                    ForEach(store.filteredFlights) { flight in
                        Button { select(flight) } label: {
                            HStack(spacing: 13) {
                                Image(systemName: "airplane").foregroundStyle(Theme.mint).frame(width: 38, height: 38).background(Theme.mint.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 4) { Text(flight.label).font(.headline).foregroundStyle(.primary); Text(flight.route).font(.caption).foregroundStyle(Theme.muted) }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) { Text(flight.aircraft ?? "--").font(.caption.weight(.medium)).foregroundStyle(.primary); Text(flight.callsign ?? "--").font(.caption2).foregroundStyle(Theme.muted) }
                                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Theme.muted)
                            }.padding(.vertical, 4)
                        }.listRowBackground(Theme.panel)
                    }
                    if store.filteredFlights.isEmpty { ContentUnavailableView.search(text: store.search) }
                }
            }.scrollContentBackground(.hidden).background(Theme.navy).navigationTitle("운항편 목록")
                .searchable(text: $store.search, prompt: "호출부호, 등록번호, 기종 검색")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
        }
    }
    @Environment(\.dismiss) private var dismiss
}

struct SettingsView: View {
    @EnvironmentObject private var store: RadarStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("앱 안내") {
                    Text(SharedRadar.disclaimer)
                    NavigationLink("개인정보 처리방침") { PrivacyView() }
                    Link("웹 개인정보 처리방침", destination: URL(string: "https://keradar-parallel.gentlevale3.chatgpt.site/privacy")!)
                    Link("지원 및 문의", destination: URL(string: "https://github.com/outinletter/kalradar/issues")!)
                }
                Section("기기 저장 항적") {
                    Text("최근 조회에 성공한 항공기 위치와 확인한 경로를 기기에 보관합니다. 저장 위치는 과거 관측 정보이며 지도 배경은 오프라인에서 표시되지 않을 수 있습니다.")
                    Button("저장 항적 삭제", role: .destructive) { store.clearSavedFlights() }
                }
                Section("데이터 모드") {
                    Picker("모드", selection: Binding(get: { store.mode }, set: { store.setMode($0) })) {
                        Text("공개 위치 조회").tag(RadarStore.Mode.live)
                        Text("가상 데모").tag(RadarStore.Mode.demo)
                    }.pickerStyle(.segmented)
                    Text("API 토큰·유료 플랜 없이 이용합니다. OpenSky는 전 세계를 조회합니다. 수신망 밖 항공기는 누락됩니다. 다른 무료 API 대체 시 인천 중심 250해리로 축소되어 화면에 표시됩니다.")
                }
                Section("자동 장애·제한 전환") {
                    Text("OpenSky(전 세계) → ADSB.lol(지역) → adsb.fi(지역) 순서입니다. 429 사용 제한, 인증 정책 변경, 서버/연결/형식 오류 시 다음 제공자를 시도합니다. 정상 빈 결과는 전환 사유가 아닙니다.")
                    Text("최소 조회 간격 30초. Retry-After와 OpenSky 대기 헤더를 존중하며 대기 중인 제공자는 건너뜁니다. 모두 실패하면 이전 응답을 표시합니다. 실행 및 앱 복귀 시 자동 조회하며 반복 타이머·백그라운드 조회는 없습니다.")
                }
                Section("필터와 한계") {
                    Text("KAL + 숫자 (+ 선택적 영문 1자) 호출부호를 추정 포함합니다. KE 공동운항 편명만으로 포함하지 않습니다. 실제 운항사·소유권을 별도로 확정하지 않습니다.")
                    Text("수신망에 따라 위치가 누락/지연됩니다. 출도착 공항과 KE 편명은 데이터가 없으면 미상으로 표시합니다. 항공 안전·항법용이 아닙니다.")
                }
                Section("출처 및 이용 조건") {
                    Link("ADSB.lol · ODbL 데이터", destination: URL(string: "https://www.adsb.lol")!)
                    Link("adsb.fi · 개인 비상업 이용", destination: URL(string: "https://adsb.fi")!)
                    Link("ADSBDB · 호출부호별 등록 경로", destination: URL(string: "https://www.adsbdb.com")!)
                    Text("선택한 항공편의 출도착 공항과 편명은 ADSBDB 등록 경로를 조회해 보완합니다. 실제 운항일의 경로·변경·경유를 보장하지 않습니다.")
                    Link("OpenSky · 익명 조회 제한", destination: URL(string: "https://openskynetwork.github.io/opensky-api/rest.html")!)
                    Text("개인용 프로토타입입니다. 공개 배포·상업 이용은 각 제공자의 이용 조건을 별도로 검토해야 합니다. 키 요구 정책은 향후 변경될 수 있습니다.")
                }
            }.font(.caption).scrollContentBackground(.hidden).background(Theme.navy)
                .navigationTitle("설정").toolbar { ToolbarItem(placement: .topBarTrailing) { Button("완료") { dismiss() } } }
        }
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("개인정보 처리방침").font(.title2.bold())
                Text("시행일: 2026년 10월 14일")
                Text("이 앱은 회원가입, 광고, 분석 SDK, 사용자 추적을 사용하지 않으며 사용자의 기기 위치, 연락처, 사진을 요청하지 않습니다. 앱 실행 및 복귀 시 항공 정보를 자동 조회합니다.")
                Text("자동 또는 수동 조회 시 OpenSky, ADSB.lol 또는 adsb.fi에 HTTPS 요청을 보냅니다. 선택한 항공편의 호출부호는 출도착 확인을 위해 ADSBDB에 전송됩니다. 이 제공자는 연결에 필요한 IP 주소와 요청 정보(앱 식별 헤더 및 고정 조회 범위)를 받을 수 있습니다. 항공편 검색어는 기기 안에서만 처리합니다.")
                Text("지도는 Apple MapKit을 이용합니다. 지도 표시를 위해 Apple 서비스에 네트워크 요청이 전달될 수 있습니다. 사용자의 현재 위치는 전송하지 않습니다.")
                Text("최근 항공기 위치, 확인한 경로와 저장 시각은 오프라인 열람을 위해 기기에 보관하며 다음 성공 조회로 갱신됩니다. 설정의 저장 항적 삭제로 제거할 수 있습니다. 검색어는 메모리에서만 처리합니다. 앱은 자체 서버에 사용자 정보를 저장하거나 판매하지 않습니다. 제공자의 서버 기록은 각 정책을 따릅니다.")
                Link("Apple 개인정보 처리방침", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
                Link("OpenSky", destination: URL(string: "https://opensky-network.org")!)
                Link("ADSB.lol", destination: URL(string: "https://www.adsb.lol")!)
                Link("adsb.fi", destination: URL(string: "https://adsb.fi")!)
            }.padding()
        }.navigationTitle("개인정보").background(Theme.navy)
    }
}

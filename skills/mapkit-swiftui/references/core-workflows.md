# MapKit Core Workflows

Reviewed 2026-10-16 with Xcode 27.0 and iOS 27.0 SDK. See [MapKit](https://developer.apple.com/documentation/mapkit) and [MapKit for SwiftUI](https://developer.apple.com/documentation/mapkit/mapkit-for-swiftui) for the target platform’s declarations. App-specific values in recipes (coordinates, results, bindings) are supplied by the integrating app.

## Contents

- SwiftUI Map, camera and bounds
- Markers, annotations, overlays and selection
- Map styles, controls and location
- Coordinate conversion and Look Around
- Search, geocoding, places and directions
- UIKit bridges, clustering and custom tiles
- Performance, privacy and service APIs

# PART 1 — THE SWIFTUI `Map` VIEW (iOS 17+)

```swift
import SwiftUI
import MapKit

struct ContentView: View { var body: some View { Map() } }   // interactive map, one line
```

### Initializers (all take a `MapContentBuilder` closure)
```swift
// Static initial camera (uncontrolled)
Map(initialPosition: .automatic, interactionModes: .all) { /* content */ }

// Two-way bound camera
Map(position: $position, bounds: nil, interactionModes: .all) { /* content */ }

// Selection-enabled (tags or MKMapItem)
Map(position: $position, selection: $selection) { /* content */ }
```
The deprecated `Map(coordinateRegion:)` (iOS 14–16) is replaced by these.

### `MapCameraPosition`
Factory methods: `.automatic` (frames content), `.region(MKCoordinateRegion)`, `.rect(MKMapRect)`, `.camera(MapCamera)`, `.item(MKMapItem, allowsAutomaticPitch:)`, `.userLocation(followsHeading:fallback:)`. Read-only props: `camera`, `region`, `rect`, `item`, and `positionedByUser: Bool` (true when the user moved the camera).

```swift
@State private var position: MapCameraPosition = .userLocation(
    fallback: .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), distance: 10_000))
)
Map(position: $position) { /* content */ }
    .mapControls { MapUserLocationButton() }
```

### `MapCamera`
```swift
MapCamera(centerCoordinate: CLLocationCoordinate2D,
          distance: Double,                 // meters from the ground point
          heading: CLLocationDirection = 0,
          pitch: CGFloat = 0)
```
Animate by wrapping the assignment in `withAnimation { position = ... }`. `mapCameraKeyframeAnimator(trigger:keyframes:)` does keyframed flythroughs. Test overlays and selection while the animation runs on the target OS.

### Observing camera changes
```swift
Map(position: $position)
    .onMapCameraChange(frequency: .onEnd) { context in     // .onEnd (default) or .continuous
        let region = context.region   // MKCoordinateRegion
        let rect   = context.rect     // MKMapRect
        let camera = context.camera   // MapCamera
    }
```
Use `.onEnd` to trigger searches (avoid hammering); `.continuous` only when you truly need live coordinates (e.g. a center-pin address readout).

### Bounds & interaction
```swift
Map(position: $position,
    bounds: MapCameraBounds(centerCoordinateBounds: region, minimumDistance: 500, maximumDistance: 50_000),
    interactionModes: [.pan, .zoom])   // option set: .pan .zoom .pitch .rotate .all
```

---

# PART 2 — CONTENT: MARKERS, ANNOTATIONS, OVERLAYS

### Marker (standard balloon pin)
```swift
Marker("Parking", systemImage: "car.fill", coordinate: parking).tint(.mint)
Marker("Foot Bridge", monogram: "FB", coordinate: bridge)   // up to 3 letters
Marker(item: mapItem)                                        // uses the place's name/icon/tint
```
### Annotation (custom SwiftUI view)
```swift
Annotation("Kings Cross", coordinate: .kingsCross, anchor: .bottom) {
    Image(systemName: "train.side.front.car")
        .padding(8).background(.blue, in: .capsule)
}
```
`anchor:` is a SwiftUI `UnitPoint` (`.center` default, `.bottom`, …). Suppress auto titles with `.annotationTitles(.hidden)`.

### Overlays (conform to `MapContent`)
```swift
MapPolyline(coordinates: coords).stroke(.blue, lineWidth: 5)
MapPolyline(route.polyline).stroke(Gradient(colors: [.red, .indigo]))   // gradient follows the line
MapPolygon(coordinates: coords).foregroundStyle(.red.opacity(0.3))
MapCircle(center: coord, radius: 500).foregroundStyle(.blue.opacity(0.2))
```
For gradient polylines pass a `Gradient` directly to `stroke(_:)` (not `linearGradient(startPoint:endPoint:)`) so it follows the line, not screen space. Control draw order with `.mapOverlayLevel(level:)` (`.aboveRoads` / `.aboveLabels`).

### Selection
```swift
@State private var selectedTag: Int?
Map(selection: $selectedTag) {
    Marker("A", coordinate: a).tag(1)
    Marker("B", coordinate: b).tag(2)
}

@State private var selected: MKMapItem?
Map(selection: $selected) { ForEach(results, id: \.self) { Marker(item: $0) } }
```

**Clustering in SwiftUI is limited** — the `Map` view doesn't expose `clusteringIdentifier`, collision modes, or custom cluster views. For real clustering of large datasets, drop to `MKMapView` (Part 9).

---

# PART 3 — MAP STYLE & POINTS OF INTEREST

```swift
Map { }.mapStyle(.standard(elevation: .realistic,
                           emphasis: .muted,                              // standard only: .automatic / .muted
                           pointsOfInterest: .including([.restaurant, .cafe]),
                           showsTraffic: true))
Map { }.mapStyle(.hybrid(elevation: .realistic, showsTraffic: true))
Map { }.mapStyle(.imagery(elevation: .realistic))                        // satellite, 3D
```
- **Elevation:** `.automatic`, `.flat`, `.realistic` (3D terrain/buildings; regional).
- **`pointsOfInterest`** uses `PointOfInterestCategories`: `.all`, `.excludingAll`, `.including([...])`, `.excluding([...])` of `MKPointOfInterestCategory`.
- **`showsTraffic`** applies to `.standard` and `.hybrid` only.

---

# PART 4 — MAP CONTROLS & USER LOCATION

```swift
Map { }.mapControls {
    MapUserLocationButton(); MapCompass(); MapPitchToggle(); MapScaleView()
}

// Custom placement via a shared scope:
@Namespace var mapScope
VStack {
    Map(scope: mapScope) { }
    HStack { MapScaleView(scope: mapScope); MapCompass(scope: mapScope) }
}.mapScope(mapScope)
```
Controls: `MapCompass`, `MapPitchToggle`, `MapScaleView`, `MapUserLocationButton`, `MapZoomStepper`/`MapPitchSlider` (Mac), `MapLocationCompass` (watchOS). Hide all with `.mapControlVisibility(.hidden)`.

**User location:** add `UserAnnotation()` inside the content closure to show the blue dot (requires authorization — Part 11).

---

# PART 5 — COORDINATE CONVERSION (`MapProxy` / `MapReader`)

```swift
MapReader { proxy in
    Map().onTapGesture { screenPoint in
        if let coord = proxy.convert(screenPoint, from: .local) { print(coord) }
    }
}
```
`MapProxy` provides `convert(_:from:)` and `convert(_:to:)` between screen points (`.local`) and `CLLocationCoordinate2D`.

---

# PART 6 — LOOK AROUND (SwiftUI + UIKit)

```swift
@State private var scene: MKLookAroundScene?

LookAroundPreview(initialScene: scene, allowsNavigation: true, showsRoadLabels: true,
                  pointsOfInterest: .all, badgePosition: .topTrailing)
// or bind a scene; full-screen viewer:
.lookAroundViewer(isPresented: $showing, initialScene: scene)

// Fetch (async; nil where unavailable):
let request = MKLookAroundSceneRequest(coordinate: coord)   // also init(mapItem:)
scene = try? await request.scene
```
Always handle `nil` (imagery is regional). For UIKit, wrap `MKLookAroundViewController` in a `UIViewControllerRepresentable`. Trigger from `.task`/`.onChange`.

---

# PART 7 — SEARCH, GEOCODING, PLACES

### Natural-language search (`MKLocalSearch`, rate-limited)
```swift
let request = MKLocalSearch.Request()
request.naturalLanguageQuery = "coffee"
request.resultTypes = .pointOfInterest                    // .pointOfInterest, .address
request.region = visibleRegion
request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.cafe])
// For an address-only search, set resultTypes = .address and an MKAddressFilter.
// On iOS 18+, regionPriority = .required restricts results to request.region.
let response = try await MKLocalSearch(request: request).start()
let items = response.mapItems                              // [MKMapItem]
```
Run searches on `.onEnd` camera changes, not continuously (returns `loadingThrottled` if hammered).

### Autocomplete (`MKLocalSearchCompleter`)
```swift
@MainActor @Observable final class LocationService: NSObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()
    var completions: [MKLocalSearchCompletion] = []
    override init() { super.init(); completer.delegate = self }
    func update(_ q: String) { completer.resultTypes = .pointOfInterest; completer.queryFragment = q }
    func completerDidUpdateResults(_ c: MKLocalSearchCompleter) { completions = c.results }
    func completer(_ c: MKLocalSearchCompleter, didFailWithError e: Error) { }
}
```
Debounce `queryFragment` (~0.2s). Resolve a completion via `MKLocalSearch.Request(completion:)`.

### Place IDs (iOS 18+) — preserve a place’s identity
```swift
guard let id = MKMapItem.Identifier(rawValue: "I63802885C8189B2B") else { return }
let item = try await MKMapItemRequest(mapItemIdentifier: id).mapItem
item.openInMaps(launchOptions: nil)                     // open in Apple Maps
```
`MKMapItem` exposes `identifier`, `alternateIdentifiers`, `name`, and `isCurrentLocation`. Not every user-selected coordinate has a Place ID. Preserve coordinates for custom pins and route points; handle failed ID resolution and alternate identifiers.

### PlaceDescriptor (iOS 26+, `GeoToolbox`)
```swift
import GeoToolbox
let descriptor = PlaceDescriptor(representations: [.coordinate(coord)], commonName: "Anna Livia Fountain")
let item = try await MKMapItemRequest(placeDescriptor: descriptor).mapItem
```

### Geocoding (iOS 26+ replaces `CLGeocoder`)
```swift
if let req = MKReverseGeocodingRequest(location: CLLocation(latitude: 39.04, longitude: -94.59)) {
    let item = try await req.mapItems.first
}
// Forward: MKGeocodingRequest
```
`MKAddress` has `fullAddress`/`shortAddress`; `MKAddressRepresentations` gives locale-aware formatting. Keep `CLGeocoder` (deprecated but available) as a fallback on pre-iOS-26 targets.

### Directions (`MKDirections`)
```swift
let request = MKDirections.Request()
// iOS 26+; use MKPlacemark on older deployment targets.
request.source = MKMapItem(location: CLLocation(latitude: start.latitude, longitude: start.longitude),
                           address: nil)
request.destination = selectedItem
request.transportType = .automobile        // .walking, .cycling (iOS 26+), .any
request.requestsAlternateRoutes = true
let response = try await MKDirections(request: request).calculate()
let route = response.routes.first          // MKRoute: polyline, distance, expectedTravelTime, steps, advisoryNotices
// .transit is supported for calculateETA(), not full calculate() routes.
// ETA-only: MKDirections(request: request).calculateETA()
Map { if let route { MapPolyline(route.polyline).stroke(.blue, lineWidth: 5) } }
```

---

# PART 8 — CAMERA, REGIONS & COORDINATE TYPES

- `CLLocationCoordinate2D(latitude:longitude:)` — lat/long degrees.
- `MKCoordinateRegion(center:span:)` or `(center:latitudinalMeters:longitudinalMeters:)`; `MKCoordinateSpan(latitudeDelta:longitudeDelta:)`.
- `MKMapRect` / `MKMapPoint` — projected (Mercator) space; `route.polyline.boundingMapRect` gives a fitting rect.
- `MKMapCamera(lookingAtCenter:fromDistance:pitch:heading:)` — the UIKit camera.
- `MKMapView.CameraBoundary` and `MKMapView.CameraZoomRange(minCenterCoordinateDistance:maxCenterCoordinateDistance:)` constrain UIKit maps.
- Distance: `CLLocation(...).distance(from:)` (meters); miles = meters / 1609.344.

---

# PART 9 — UIKIT `MKMapView` BRIDGE (when SwiftUI isn't enough)

**Use UIKit for an existing UIKit map or for:** custom tile overlays (`MKTileOverlay`/`MKTileOverlayRenderer`); real clustering with `clusteringIdentifier`/`displayPriority`/`collisionMode`/custom cluster views; custom overlay renderers (gradient/per-overlay alpha, `MKMultiPolyline`/`MKMultiPolygon` performance); configuration features not surfaced in SwiftUI.

```swift
struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    func makeUIView(context: Context) -> MKMapView {
        let mv = MKMapView(); mv.delegate = context.coordinator; return mv
    }
    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.parent = self // refresh bindings after SwiftUI recreates the value
        let fitted = uiView.regionThatFits(region)
        if !Self.approximatelyEqual(uiView.region, fitted) {
            uiView.setRegion(fitted, animated: false)
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    static func approximatelyEqual(_ a: MKCoordinateRegion, _ b: MKCoordinateRegion) -> Bool {
        let epsilon = 0.000001
        return abs(a.center.latitude - b.center.latitude) < epsilon
            && abs(a.center.longitude - b.center.longitude) < epsilon
            && abs(a.span.latitudeDelta - b.span.latitudeDelta) < epsilon
            && abs(a.span.longitudeDelta - b.span.longitudeDelta) < epsilon
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        init(_ p: MapView) { parent = p }
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            let visibleRegion = mapView.region
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      !MapView.approximatelyEqual(self.parent.region, visibleRegion) else { return }
                self.parent.region = visibleRegion
            }
        }
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tile = overlay as? MKTileOverlay { return MKTileOverlayRenderer(tileOverlay: tile) }
            if let line = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: line); r.strokeColor = .systemBlue; r.lineWidth = 4; return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? { nil /* dequeue + reuse */ }
    }
}
```
**Representable rules of thumb:** in `updateUIView` set only properties that genuinely changed; push SwiftUI state from delegate callbacks asynchronously to dodge "Modifying state during view update". Do not assume a recreated representable struct recreates or leaks its UIKit view. Diagnose ownership with Instruments, cancel outstanding requests, and clean up delegates in `dismantleUIView` when appropriate. For complex two-way camera animation, coordinate programmatic changes and user gestures explicitly to discard stale callbacks.

**Key delegate methods:** `mapView(_:rendererFor:)`, `mapView(_:viewFor:)`, `mapView(_:didSelect:)`, `mapView(_:calloutAccessoryControlTapped:)`, `mapViewDidChangeVisibleRegion(_:)`, `mapView(_:regionDidChangeAnimated:)`.

**Custom tiles (replace the example URL with your provider):**
```swift
let overlay = MKTileOverlay(urlTemplate: "https://tiles.example.com/{z}/{x}/{y}.png")
overlay.canReplaceMapContent = true; overlay.minimumZ = 1; overlay.maximumZ = 18
mapView.addOverlay(overlay, level: .aboveLabels)   // renderer: MKTileOverlayRenderer(tileOverlay:)
```

**Clustering (UIKit):** automatic on iOS 11+ when annotation views share a `clusteringIdentifier`.
```swift
final class StationView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        didSet { clusteringIdentifier = "station"; displayPriority = .defaultLow }
    }
}
final class ClusterView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        didSet {
            guard let cluster = annotation as? MKClusterAnnotation else { return }
            let count = cluster.memberAnnotations.count
            let label = count > 999 ? "999+" : String(count)
            let size = CGSize(width: 48, height: 24)
            glyphText = nil
            glyphImage = UIGraphicsImageRenderer(size: size).image { _ in
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: UIColor.white
                ]
                let textSize = (label as NSString).size(withAttributes: attributes)
                (label as NSString).draw(at: CGPoint(x: (size.width - textSize.width) / 2,
                                                     y: (size.height - textSize.height) / 2),
                                        withAttributes: attributes)
            }.withRenderingMode(.alwaysTemplate)
            collisionMode = .circle
        }
    }
}
mapView.register(StationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
mapView.register(ClusterView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
```
`displayPriority` (`.required`/`.defaultHigh`/`.defaultLow`) decides collision survivors; `collisionMode` is `.rectangle` or `.circle`.

---

# PART 10 — 3D / FLYOVER

`MKMapType` (soft-deprecated, still functional): `.standard`, `.satellite`, `.hybrid`, `.satelliteFlyover`, `.hybridFlyover`. SwiftUI equivalent: `.mapStyle(.imagery(elevation: .realistic))` / `.hybrid(elevation: .realistic)`. Flyover/realistic 3D is regional. Handle regional availability rather than promising identical imagery everywhere.

---

# PART 11 — PERFORMANCE, PRIVACY & GOTCHAS

- **Annotation identity:** make annotation data `Identifiable` with STABLE ids; never reuse `UUID()` per render (breaks diffing → flicker/selection bugs).
- **Camera churn:** binding `position` and writing it back inside `.onMapCameraChange(.continuous)` causes re-render loops; prefer `.onEnd` and don't reassign the same value.
- **Search throttling:** debounce `MKLocalSearchCompleter.queryFragment`; gate `MKLocalSearch.start()` behind `.onEnd`. Expect `loadingThrottled` if hammered.
- **Geocoding:** never call synchronously on the main thread in a loop; prefer async MapKit geocoding (iOS 26+); `CLGeocoder` is rate-limited.
- **Overlay performance:** batch many shapes into `MKMultiPolyline`/`MKMultiPolygon`; reuse one renderer.
- **UIKit reuse:** always dequeue annotation views with a reuse identifier; never create a fresh view per annotation for large datasets.
- **Privacy / authorization:** add `NSLocationWhenInUseUsageDescription` (and the Always key if needed) to Info.plist; request via `CLLocationManager.requestWhenInUseAuthorization()`. The blue dot / `UserAnnotation()` won't appear without authorization. Request location only when the feature needs it; prefer when-in-use.

---

# PART 12 — MapKit JS & APPLE MAPS SERVER API (brief)

- **MapKit JS:** interactive Apple Maps on the web (macOS/Windows/Android, all browsers); JWT token auth; `mapkit.load`, `Search`, `PlaceLookup`, `LookAround`, Place Cards.
- **Apple Maps Server API:** REST geocoding / reverse geocoding / search / directions / ETA from a backend; same JWT auth.
- **Quotas and credentials:** check the current [Maps developer service documentation](https://developer.apple.com/maps/) and account limits. Keep signing keys on the server, and handle quota/network errors.
- **When:** Server API to offload geocoding/search/ETA to a backend or share across native + web; MapKit JS for web parity. For Apple-platform app maps, consider native MapKit first.

---

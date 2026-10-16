---
name: mapkit-swiftui
description: "Build or debug Apple-platform maps with MapKit: SwiftUI Map, markers and annotations, camera control, selection, overlays, search and autocomplete, geocoding, Look Around, directions, and MKMapView bridges for clustering or custom rendering. Use when the task involves MapKit or Apple maps; unrelated web mapping libraries are outside this skill."
license: MIT
---

# MapKit for iOS (SwiftUI-first, iOS 27 / WWDC 2026 current)

Reviewed 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27.0 SDK. Check the target platform and deployment version for each API; newer SDK availability does not imply that a consumer service is enabled for every account or region. Code using app stores, routers, or model types is an integration sketch; supply those app-specific dependencies.

Build maps the modern way: default to **MapKit for SwiftUI** (the `Map` view + `MapContentBuilder`, iOS 17+), which covers the large majority of consumer-app needs declaratively. Use UIKit `MKMapView` when the app already uses UIKit or the requested behavior needs its delegate, clustering, tile, or rendering APIs (Part 9).

For location authorization, see [Core Location](https://developer.apple.com/documentation/corelocation). Optional companion skills cover adaptive layout and native design; this skill has no required skill dependencies.

## What's new / version map (what shipped when)

| Cycle | Additions |
|-------|-----------|
| iOS 16 (WWDC22) | Look Around in MapKit; configuration classes (`MKStandardMapConfiguration`/`MKHybridMapConfiguration`/`MKImageryMapConfiguration`); `MKMapType` soft-deprecated |
| **iOS 17 (WWDC23)** | **The SwiftUI `Map` rewrite** — `MapContentBuilder`, `Marker`, `Annotation`, `MapPolyline`/`MapPolygon`/`MapCircle`, `MapCameraPosition`, `onMapCameraChange`, `mapStyle`, map controls, `LookAroundPreview`, `MapProxy`/`MapReader`. Old `Map(coordinateRegion:)` deprecated |
| iOS 18 (WWDC24) | `MKMapItem.Identifier` (stable Place ID), `MKMapItemRequest(mapItemIdentifier:)`, Place Cards / `SelectionAccessory`, `MKAddressFilter`, region-restricted search |
| iOS 26 (WWDC25) | `GeoToolbox.PlaceDescriptor` + `MKMapItemRequest(placeDescriptor:)`; geocoding moved into MapKit (`MKGeocodingRequest`, `MKReverseGeocodingRequest`, `MKAddress`, `MKAddressRepresentations`); `CLGeocoder` deprecated; `.cycling` transport type; 20+ MapKit APIs on watchOS; Look Around in MapKit JS |

Use the deployment SDK to check newer symbols and availability. Do not infer developer API behavior from consumer Maps imagery announcements or an absence of conference sessions.

---

## Load the detailed recipes when needed

Read [references/core-workflows.md](references/core-workflows.md) for the selected task:

- Parts 1–4: SwiftUI map content, camera, selection, styles, controls, and user location.
- Parts 5–6: coordinate conversion and unavailable Look Around scenes.
- Part 7: search/autocomplete, place identity, geocoding, and directions. Cancel or ignore stale responses, handle errors, and use transit only for ETA calculations.
- Parts 8–9: coordinate types and UIKit bridging, including camera feedback and clustering.
- Parts 10–12: 3D availability, performance, location permissions, and web/server API boundaries.

# RECOMMENDATIONS

1. **For a SwiftUI app, start with MapKit for SwiftUI** — `Map(position:)` + `MapCameraPosition` + `Marker`/`Annotation` + `.mapStyle`.
2. **Use UIKit when it fits the app or required APIs:** existing UIKit architecture, clustering, custom tiles/renderers, or measured performance needs can justify `MKMapView` regardless of pin count.
3. **Wire search correctly:** debounced `MKLocalSearchCompleter` typeahead → `MKLocalSearch.Request(completion:)` to resolve → `Marker(item:)` + `Map(selection:)`. Debounce text input and resolve the selected completion; use camera `.onEnd` only for searches triggered by map movement.
4. **Persist Place IDs** (`MKMapItem.Identifier.rawValue`) when referring to a known place; preserve coordinates for custom pins and recorded routes. Use `PlaceDescriptor` when resolving a name/address/coordinate.
5. **Migrate geocoding** to `MKGeocodingRequest`/`MKReverseGeocodingRequest` at iOS 26 target; keep `CLGeocoder` fallback below that.
6. **Render numeric map UI with tabular digits**: distances, ETAs, coordinates, cluster counts, and changing search counts need `.monospacedDigit()` or a tabular UIKit font, with stable field widths.

## Verification and primary references

- Test unavailable Look Around scenes, failed place resolution, cancelled searches, denied location access, stale search responses, and camera updates that change only longitude or span.
- Compare iOS 17/18/26 availability against the deployment target; MapKit geocoding, `PlaceDescriptor`, and cycling require iOS 26.
- [MapKit for SwiftUI](https://developer.apple.com/documentation/mapkit/mapkit-for-swiftui)
- [MapKit](https://developer.apple.com/documentation/mapkit)
- [Transit transport limitations](https://developer.apple.com/documentation/mapkit/mkdirectionstransporttype/transit)
- [GeoToolbox](https://developer.apple.com/documentation/geotoolbox)

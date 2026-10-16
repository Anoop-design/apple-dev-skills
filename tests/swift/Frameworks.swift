// Representative compile probes for reviewed framework guidance.
// SDK type checking only; no account, purchase, health-data, or network operations run.
import AppIntents
import CloudKit
import CoreTransferable
import GeoToolbox
import HealthKit
import MapKit
import StoreKit
import SwiftUI

struct ReviewLandmark: AppEntity, Transferable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Landmark"
    static let defaultQuery = ReviewLandmarkQuery()
    var displayRepresentation: DisplayRepresentation { .init(title: "\(name)") }
    static var transferRepresentation: some TransferRepresentation {
        IntentValueRepresentation(exporting: { (entity: ReviewLandmark) in
            PlaceDescriptor(representations: [.coordinate(entity.coordinate)], commonName: entity.name)
        })
    }
}
struct ReviewLandmarkQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [ReviewLandmark] { [] }
}
struct ReviewBulkIntent: AppIntent {
    static let title: LocalizedStringResource = "Review Landmarks"
    static var allowedExecutionTargets: IntentExecutionTargets { [.main] }
    @Parameter(title: "Landmarks") var landmarks: EntityCollection<ReviewLandmark>
    func perform() async throws -> some IntentResult {
        let _: [UUID] = landmarks.identifiers
        return .result()
    }
}
func reviewRelevantEntities(_ landmarks: [ReviewLandmark], context: AppEntityContext) async throws {
    try await RelevantEntities.shared.updateEntities(landmarks, for: context)
    try await RelevantEntities.shared.removeEntities(landmarks, from: context)
    try await RelevantEntities.shared.removeAllEntities(for: context)
}
struct ReviewExportIntent: LongRunningIntent, CancellableIntent {
    static let title: LocalizedStringResource = "Review Export"
    func perform() async throws -> some IntentResult {
        progress.totalUnitCount = 1
        try await performBackgroundTask {
            try Task.checkCancellation()
            progress.completedUnitCount = 1
        } onCancel: { _ in }
        return .result()
    }
}
@AppIntent(schema: .system.searchInApp)
struct ReviewSearchIntent: AppIntent {
    static let title: LocalizedStringResource = "Search Review"
    @Parameter(title: "Search") var criteria: StringSearchCriteria
    @MainActor func perform() async throws -> some IntentResult {
        let _: String = criteria.term
        return .result()
    }
}
func reviewHealth(_ store: HKHealthStore, sourceRevision: HKSourceRevision) async throws {
    let read: Set<HKObjectType> = [HKQuantityType(.stepCount), HKQuantityType(.heartRate)]
    let share: Set<HKSampleType> = [HKQuantityType(.activeEnergyBurned)]
    try await store.requestAuthorization(toShare: share, read: read)
    let predicate = HKQuery.predicateForObjects(from: [sourceRevision])
    let samples = HKSampleQueryDescriptor(
        predicates: [.quantitySample(type: HKQuantityType(.heartRate), predicate: predicate)],
        sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)], limit: 100)
    _ = try await samples.result(for: store)
    let statistics = HKStatisticsQueryDescriptor(
        predicate: .quantitySample(type: HKQuantityType(.stepCount), predicate: predicate),
        options: .cumulativeSum)
    _ = try await statistics.result(for: store)?.sumQuantity()?.doubleValue(for: .count())
    let anchored = HKAnchoredObjectQueryDescriptor(
        predicates: [.sample(type: HKQuantityType(.bodyMass), predicate: nil)], anchor: nil)
    _ = try await anchored.result(for: store)
    _ = HKUserAnnotatedMedicationQueryDescriptor()
}
func reviewWorkout(_ store: HKHealthStore, locations: [CLLocation]) async throws {
    let config = HKWorkoutConfiguration()
    config.activityType = .running
    let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
    let bpm = HKUnit.count().unitDivided(by: .minute())
    let zones = try HKWorkoutZoneConfiguration(quantityType: HKQuantityType(.heartRate),
        zoneBoundaries: [100, 120, 140, 160].map { HKQuantity(unit: bpm, doubleValue: $0) })
    try await builder.setCustomZoneConfiguration(zones, for: HKQuantityType(.heartRate))
    _ = try await builder.zoneConfiguration(for: HKQuantityType(.heartRate))
    try await builder.beginCollection(at: Date())
    guard let route = builder.seriesBuilder(for: .workoutRoute()) as? HKWorkoutRouteBuilder else { return }
    try await route.insertRouteData(locations)
    try await builder.endCollection(at: Date())
    let workout = try await builder.finishWorkout()
    _ = workout?.zoneGroupsByType?[HKQuantityType(.heartRate)]
}
func reviewCloud(_ database: CKDatabase, records: [CKRecord]) async throws {
    let (saves, _) = try await database.modifyRecords(saving: records, deleting: [], atomically: true)
    for result in saves.values { _ = try result.get() }
    let query = CKQuery(recordType: "ReviewNote", predicate: NSPredicate(value: true))
    var (_, cursor) = try await database.records(matching: query)
    while let next = cursor {
        (_, cursor) = try await database.records(continuingMatchFrom: next)
    }
}
@MainActor
func reviewPurchase(_ product: Product, offerID: String, signedOffer: String) async throws {
    let terms = product.subscription?.pricingTerms.first { $0.billingPlanType == .monthly }
    let _: String? = terms?.commitmentInfo.displayPrice
    let _: Decimal? = terms?.commitmentInfo.price
    let options = Set(Product.PurchaseOption.promotionalOffer(offerID, compactJWS: signedOffer))
    _ = try await product.purchase(options: options)
    _ = try await product.purchase(options: [.billingPlanType(.monthly)])
}
struct ReviewPaywall: View {
    @State private var redeem = false
    var body: some View {
        SubscriptionStoreView(groupID: "review-only")
            .preferredSubscriptionPricingTerms { _, info in
                info.pricingTerms.first { $0.billingPlanType == .monthly }
            }
            .offerCodeRedemption(options: [], isPresented: $redeem) { result in
                if case .success(.verified(let transaction)) = result {
                    let _: UInt64 = transaction.id
                    // Production: enqueue durable fulfillment before finishing.
                }
            }
    }
}
@MainActor
func reviewMaps(_ coordinate: CLLocationCoordinate2D) async throws {
    let descriptor = PlaceDescriptor(representations: [.coordinate(coordinate)], commonName: "Review")
    _ = try await MKMapItemRequest(placeDescriptor: descriptor).mapItem
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    if let reverse = MKReverseGeocodingRequest(location: location) {
        _ = try await reverse.mapItems.first
    }
    _ = MKMapItem(location: location, address: nil)
}

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

import Combine
import StoreKit

// Handles only non-consumables and auto-renewable subscriptions.
@MainActor
final class Store: ObservableObject {
    @Published private(set) var activeProductIDs: Set<String> = []
    private var updates: Task<Void, Never>?

    init() {
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled else { return }
                guard case .verified(let txn) = result,
                      txn.productType == .nonConsumable || txn.productType == .autoRenewable
                else { continue }
                guard let self else { return }
                await self.refreshEntitlements() // adds AND removes access
                await txn.finish()
            }
        }
        Task { [weak self] in await self?.refreshEntitlements() }
    }

    func refreshEntitlements() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let txn) = result,
                  txn.productType == .nonConsumable || txn.productType == .autoRenewable
            else { continue }
            active.insert(txn.productID)
        }
        activeProductIDs = active
    }

    deinit { updates?.cancel() }
}

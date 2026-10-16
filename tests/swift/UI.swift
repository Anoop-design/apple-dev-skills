// Representative UI APIs from the skills. Typecheck only; runtime rendering is separate.
import SwiftUI
import UIKit
import QuartzCore
import Observation

@available(iOS 26.0, *)
struct ReviewedGlassActions: View {
    @Namespace private var glass
    @State private var expanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        GlassEffectContainer(spacing: 24) {
            HStack(spacing: 16) {
                Button(expanded ? "Less" : "More") {
                    withAnimation(reduceMotion ? nil : .smooth) { expanded.toggle() }
                }
                .padding()
                .glassEffect(.regular.interactive(), in: Capsule())
                .glassEffectID("toggle", in: glass)
                if expanded {
                    Button("Share", systemImage: "square.and.arrow.up") { }
                        .padding()
                        .glassEffect(.regular.tint(.blue), in: Circle())
                        .glassEffectID("share", in: glass)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) { Button("Edit") { } }
            ToolbarSpacer(.fixed, placement: .primaryAction)
            ToolbarItem(placement: .primaryAction) { Button("Share") { } }
        }
    }
}

@available(iOS 26.0, *)
struct ReviewedTabAndBadge: View {
    let count: Int
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                ScrollView { Text("Content").backgroundExtensionEffect() }
                    .scrollEdgeEffectStyle(.hard, for: .top)
            }
            Tab(role: .search) { Text("Search") }
        }
        .tabViewBottomAccessory {
            Text("999+").hidden().overlay(alignment: .trailing) {
                Text(count > 999 ? "999+" : String(max(0, count)))
            }
            .font(.caption).monospacedDigit()
            .padding().glassEffect(.regular.tint(.red), in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Count")
            .accessibilityValue(String(max(0, count)))
        }
    }
}

extension View {
    @ViewBuilder func reviewedAdaptiveGlass() -> some View {
        if #available(iOS 26, *) { self.glassEffect(.regular, in: Capsule()) }
        else if #available(iOS 15, *) { self.background(.regularMaterial, in: Capsule()) }
        else { self.background(Capsule().fill(Color.gray.opacity(0.2))) }
    }
}

@MainActor @available(iOS 26, *)
func reviewedUIKitGlass(content: UIView, scrollView: UIScrollView) -> UIVisualEffectView {
    let effect = UIGlassEffect(style: .regular)
    effect.tintColor = .systemBlue
    effect.isInteractive = true
    let glass = UIVisualEffectView(effect: effect)
    glass.cornerConfiguration = .capsule()
    glass.cornerConfiguration = .corners(radius: .fixed(16))
    glass.cornerConfiguration = .corners(radius: .containerConcentric(minimum: 8))
    let containerEffect = UIGlassContainerEffect()
    containerEffect.spacing = 20
    let container = UIVisualEffectView(effect: containerEffect)
    container.contentView.addSubview(glass)
    glass.contentView.addSubview(content)
    scrollView.topEdgeEffect.style = .hard
    let extensionView = UIBackgroundExtensionView()
    extensionView.contentView = UIImageView()
    return container
}

@MainActor
func reviewedRetarget(layer: CALayer, position: CGPoint) {
    let current = layer.presentation()?.position ?? layer.position
    let animation = CABasicAnimation(keyPath: "position")
    animation.fromValue = NSValue(cgPoint: CGPoint(x: current.x-position.x, y: current.y-position.y))
    animation.toValue = NSValue(cgPoint: .zero)
    animation.isAdditive = true
    animation.duration = 0.3
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    layer.position = position
    CATransaction.commit()
    layer.add(animation, forKey: "position")
}

@MainActor final class ReviewedReflectionView: UIView {
    override class var layerClass: AnyClass { CAReplicatorLayer.self }
    override func layoutSubviews() {
        super.layoutSubviews()
        let replicator = layer as! CAReplicatorLayer
        replicator.instanceCount = 2
        replicator.instanceTransform = CATransform3DConcat(
            CATransform3DMakeScale(1, -1, 1),
            CATransform3DMakeTranslation(0, bounds.height * 2 + 5, 0))
        replicator.instanceAlphaOffset = -0.6
    }
}

@available(iOS 17, *)
struct ReviewedRotateTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content.rotationEffect(.degrees(phase.value * 90))
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

@available(iOS 17, *)
func reviewedTimeline(progress: Double) -> Double {
    let spring = Spring(duration: 0.5, bounce: 0.2)
    _ = spring.value(target: 100.0, time: 0.3)
    _ = spring.velocity(target: 100.0, time: 0.3)
    _ = spring.settlingDuration
    let timeline = KeyframeTimeline(initialValue: 0.0) {
        KeyframeTrack(\.self) { SpringKeyframe(1.0, spring: spring) }
    }
    return timeline.value(progress: min(1, max(0, progress)))
}

@available(iOS 17, *)
struct ReviewedShaderView: View {
    @State private var start = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let time = context.date.timeIntervalSince(start)
            Rectangle().distortionEffect(
                ShaderLibrary.wave(.float(time), .float(10), .float(0.05)),
                maxSampleOffset: CGSize(width: 10, height: 0))
        }
    }
}

@available(iOS 18, *)
func reviewedShaderArguments(url: URL, bounds: CGRect, point: CGPoint) async throws {
    let library = ShaderLibrary(url: url)
    let shader = library.reviewedColor(.float(0.5), .float2(point),
        .float3(1.0, 2.0, 3.0),
        .float4(bounds.minX, bounds.minY, bounds.width, bounds.height),
        .floatArray([1, 2, 3]), .color(.red))
    try await shader.compile(as: .colorEffect)
}

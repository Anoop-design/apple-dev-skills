// SDK/typechecking probe, not a complete camera app. No capture is started by this file.
import AVFoundation
import CoreMedia
import SwiftUI
import UIKit

// Session graph changes and start/stop stay on this actor. No suspension occurs
// between beginConfiguration and commitConfiguration, or during start/stop.
actor CameraSessionOwner {
    enum Failure: Error { case unauthorized, unavailable, invalidConfiguration }
    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var configured = false

    func start() throws {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            throw Failure.unauthorized
        }
        if !configured { try configure() }
        if !session.isRunning { session.startRunning() }
    }

    func stop() {
        if session.isRunning { session.stopRunning() }
    }

    private func configure() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw Failure.unavailable
        }
        let input = try AVCaptureDeviceInput(device: device)
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        guard session.canSetSessionPreset(.photo), session.canAddInput(input) else {
            throw Failure.invalidConfiguration
        }
        session.sessionPreset = .photo
        session.addInput(input)
        guard session.canAddOutput(output) else {
            session.removeInput(input)
            throw Failure.invalidConfiguration
        }
        session.addOutput(output)
        output.maxPhotoQualityPrioritization = .quality
        if let dimensions = device.activeFormat.supportedMaxPhotoDimensions.max(by: {
            Int64($0.width) * Int64($0.height) < Int64($1.width) * Int64($1.height)
        }) {
            output.maxPhotoDimensions = dimensions
        }
        configured = true
    }
}

@MainActor
final class CameraPreviewSurface: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// The caller supplies the capture rotation value from its RotationCoordinator.
// Call from the same isolation domain that owns the output and connection.
func makeCameraPhotoSettings(output: AVCapturePhotoOutput, angle: CGFloat) -> AVCapturePhotoSettings {
    let settings: AVCapturePhotoSettings
    if output.availablePhotoCodecTypes.contains(.hevc) {
        settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
    } else {
        settings = AVCapturePhotoSettings()
    }
    settings.maxPhotoDimensions = output.maxPhotoDimensions
    settings.photoQualityPrioritization = .quality
    if output.supportedFlashModes.contains(.auto) { settings.flashMode = .auto }
    if let connection = output.connection(with: .video), connection.isVideoRotationAngleSupported(angle) {
        connection.videoRotationAngle = angle
    }
    return settings
}

// This actor-isolated excerpt shows capability checks and the required lock.
actor CameraControls {
    func focus(device: AVCaptureDevice, normalizedPoint: CGPoint) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
            device.focusPointOfInterest = normalizedPoint
            device.focusMode = .autoFocus
        }
        if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
            device.exposurePointOfInterest = normalizedPoint
            device.exposureMode = .autoExpose
        }
    }
}

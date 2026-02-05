import SwiftUI
import AVFoundation
import Photos

/// Camera View Model
/// Manages camera session, capture, and permissions

@Observable
final class CameraViewModel: NSObject {
    // MARK: - State

    var isSessionRunning = false
    var isCameraAuthorized = false
    var isPhotoLibraryAuthorized = false
    var capturedImage: UIImage?
    var isCapturing = false
    var isFlashOn = false
    var error: CameraError?

    // MARK: - Camera Session

    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?

    // MARK: - Configuration

    private let sessionQueue = DispatchQueue(label: "com.fuel.camera.session")

    // MARK: - Initialization

    override init() {
        super.init()
        checkPermissions()
    }

    // MARK: - Permissions

    func checkPermissions() {
        // Camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            requestCameraPermission()
        case .denied:
            isCameraAuthorized = false
            error = .permissionDenied
        case .restricted:
            // Restricted by parental controls or device management
            isCameraAuthorized = false
            error = .permissionRestricted
        @unknown default:
            isCameraAuthorized = false
        }

        // Photo library permission
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            isPhotoLibraryAuthorized = true
        case .notDetermined:
            requestPhotoLibraryPermission()
        case .denied, .restricted:
            isPhotoLibraryAuthorized = false
        @unknown default:
            isPhotoLibraryAuthorized = false
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.isCameraAuthorized = granted
                if granted {
                    self?.setupSession()
                }
            }
        }
    }

    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                self?.isPhotoLibraryAuthorized = status == .authorized || status == .limited
            }
        }
    }

    // MARK: - Session Setup

    func setupSession() {
        guard isCameraAuthorized else { return }

        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Add video input
        do {
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                throw CameraError.deviceNotAvailable
            }

            let videoInput = try AVCaptureDeviceInput(device: videoDevice)

            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                videoDeviceInput = videoInput
            } else {
                throw CameraError.cannotAddInput
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.error = .setupFailed(error)
            }
            session.commitConfiguration()
            return
        }

        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.error = .cannotAddOutput
            }
        }

        session.commitConfiguration()
    }

    // MARK: - Session Control

    func startSession() {
        guard isCameraAuthorized else { return }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if !self.session.isRunning {
                self.session.startRunning()
                let isRunning = self.session.isRunning

                DispatchQueue.main.async { [weak self] in
                    self?.isSessionRunning = isRunning
                }
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if self.session.isRunning {
                self.session.stopRunning()

                DispatchQueue.main.async { [weak self] in
                    self?.isSessionRunning = false
                }
            }
        }
    }

    // MARK: - Capture

    func capturePhoto() {
        guard !isCapturing else { return }

        isCapturing = true
        FuelHaptics.shared.capture()

        let settings = AVCapturePhotoSettings()

        // Configure flash
        if let device = videoDeviceInput?.device,
           device.hasFlash {
            settings.flashMode = isFlashOn ? .on : .off
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func toggleFlash() {
        isFlashOn.toggle()
        FuelHaptics.shared.tap()
    }

    // MARK: - Photo Management

    func retakePhoto() {
        capturedImage = nil
        FuelHaptics.shared.tap()
    }

    func savePhotoToLibrary() {
        guard let image = capturedImage else { return }

        // Check permission before attempting save
        guard isPhotoLibraryAuthorized else {
            error = .photoLibraryPermissionDenied
            FuelHaptics.shared.error()
            return
        }

        PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.creationRequestForAsset(from: image)
        } completionHandler: { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    FuelHaptics.shared.success()
                } else {
                    self?.error = .photoSaveFailed(error)
                    FuelHaptics.shared.error()
                }
            }
        }
    }

    // MARK: - Open Settings

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isCapturing = false

            if let error = error {
                self?.error = .captureFailed(error)
                FuelHaptics.shared.error()
                return
            }

            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                self?.error = .imageProcessingFailed
                FuelHaptics.shared.error()
                return
            }

            self?.capturedImage = image
            FuelHaptics.shared.success()
        }
    }
}

// MARK: - Camera Error

enum CameraError: LocalizedError {
    case deviceNotAvailable
    case cannotAddInput
    case cannotAddOutput
    case setupFailed(Error)
    case captureFailed(Error)
    case imageProcessingFailed
    case permissionDenied
    case permissionRestricted
    case photoLibraryPermissionDenied
    case photoSaveFailed(Error?)

    var errorDescription: String? {
        switch self {
        case .deviceNotAvailable:
            return "Camera device not available"
        case .cannotAddInput:
            return "Cannot configure camera input"
        case .cannotAddOutput:
            return "Cannot configure camera output"
        case .setupFailed(let error):
            return "Camera setup failed: \(error.localizedDescription)"
        case .captureFailed(let error):
            return "Photo capture failed: \(error.localizedDescription)"
        case .imageProcessingFailed:
            return "Failed to process captured image"
        case .permissionDenied:
            return "Camera permission denied. Please enable in Settings."
        case .permissionRestricted:
            return "Camera access is restricted by device policy"
        case .photoLibraryPermissionDenied:
            return "Photo library permission denied. Please enable in Settings."
        case .photoSaveFailed(let error):
            return "Failed to save photo: \(error?.localizedDescription ?? "Unknown error")"
        }
    }
}

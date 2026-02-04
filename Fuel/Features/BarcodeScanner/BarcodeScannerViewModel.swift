import SwiftUI
import AVFoundation

/// Barcode Scanner View Model
/// Manages camera session for barcode detection using AVFoundation

@Observable
final class BarcodeScannerViewModel: NSObject {
    // MARK: - State

    var isSessionRunning = false
    var isCameraAuthorized = false
    var isTorchOn = false
    var isProcessing = false
    var scannedBarcode: String?
    var error: BarcodeScannerError?

    // MARK: - Callbacks

    var onBarcodeDetected: ((String) -> Void)?

    // MARK: - Camera Session

    let session = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?

    // MARK: - Configuration

    private let sessionQueue = DispatchQueue(label: "com.fuel.barcode.session")
    private let supportedBarcodeTypes: [AVMetadataObject.ObjectType] = [
        .ean8,
        .ean13,
        .upce,
        .code128,
        .code39,
        .code93,
        .itf14,
        .dataMatrix,
        .qr
    ]

    // Debounce to prevent multiple scans
    private var lastScannedCode: String?
    private var lastScanTime: Date?
    private let scanDebounceInterval: TimeInterval = 2.0

    // MARK: - Initialization

    override init() {
        super.init()
        checkPermissions()
    }

    // MARK: - Permissions

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            requestCameraPermission()
        default:
            isCameraAuthorized = false
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

    // MARK: - Session Setup

    func setupSession() {
        guard isCameraAuthorized else { return }

        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Add video input
        do {
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                throw BarcodeScannerError.deviceNotAvailable
            }

            // Configure for barcode scanning
            try configureDevice(videoDevice)

            let videoInput = try AVCaptureDeviceInput(device: videoDevice)

            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                videoDeviceInput = videoInput
            } else {
                throw BarcodeScannerError.cannotAddInput
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.error = .setupFailed(error)
            }
            session.commitConfiguration()
            return
        }

        // Add metadata output for barcode detection
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

            // Set supported barcode types
            let availableTypes = metadataOutput.availableMetadataObjectTypes
            let typesToSet = supportedBarcodeTypes.filter { availableTypes.contains($0) }
            metadataOutput.metadataObjectTypes = typesToSet
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.error = .cannotAddOutput
            }
        }

        session.commitConfiguration()
    }

    private func configureDevice(_ device: AVCaptureDevice) throws {
        try device.lockForConfiguration()

        // Enable auto-focus for barcode scanning
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }

        // Enable auto-exposure
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }

        device.unlockForConfiguration()
    }

    // MARK: - Session Control

    func startSession() {
        guard isCameraAuthorized else { return }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if !self.session.isRunning {
                self.session.startRunning()

                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                    self.scannedBarcode = nil
                    self.lastScannedCode = nil
                }
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if self.session.isRunning {
                self.session.stopRunning()

                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }

    // MARK: - Torch Control

    func toggleTorch() {
        guard let device = videoDeviceInput?.device,
              device.hasTorch else { return }

        do {
            try device.lockForConfiguration()

            if device.torchMode == .on {
                device.torchMode = .off
                isTorchOn = false
            } else {
                try device.setTorchModeOn(level: 0.8)
                isTorchOn = true
            }

            device.unlockForConfiguration()
            FuelHaptics.shared.tap()
        } catch {
            self.error = .torchFailed
        }
    }

    // MARK: - Scanning Control

    func resetScanner() {
        scannedBarcode = nil
        lastScannedCode = nil
        lastScanTime = nil
        isProcessing = false
    }

    // MARK: - Open Settings

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        // Skip if already processing
        guard !isProcessing else { return }

        // Get barcode value
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let barcodeValue = metadataObject.stringValue else {
            return
        }

        // Debounce: skip if same code scanned recently
        let now = Date()
        if let lastCode = lastScannedCode,
           let lastTime = lastScanTime,
           lastCode == barcodeValue,
           now.timeIntervalSince(lastTime) < scanDebounceInterval {
            return
        }

        // Update state
        lastScannedCode = barcodeValue
        lastScanTime = now
        scannedBarcode = barcodeValue
        isProcessing = true

        // Haptic feedback
        FuelHaptics.shared.success()

        // Notify callback
        onBarcodeDetected?(barcodeValue)
    }
}

// MARK: - Barcode Scanner Error

enum BarcodeScannerError: LocalizedError {
    case deviceNotAvailable
    case cannotAddInput
    case cannotAddOutput
    case setupFailed(Error)
    case torchFailed
    case permissionDenied
    case productNotFound
    case lookupFailed(Error)

    var errorDescription: String? {
        switch self {
        case .deviceNotAvailable:
            return "Camera device not available"
        case .cannotAddInput:
            return "Cannot configure camera input"
        case .cannotAddOutput:
            return "Cannot configure barcode scanner"
        case .setupFailed(let error):
            return "Scanner setup failed: \(error.localizedDescription)"
        case .torchFailed:
            return "Failed to toggle flashlight"
        case .permissionDenied:
            return "Camera permission denied"
        case .productNotFound:
            return "Product not found in database"
        case .lookupFailed(let error):
            return "Lookup failed: \(error.localizedDescription)"
        }
    }
}

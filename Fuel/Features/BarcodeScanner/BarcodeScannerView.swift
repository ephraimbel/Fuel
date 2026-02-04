import SwiftUI
import AVFoundation

/// Barcode Scanner View
/// Full-screen barcode scanning interface for food products

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = BarcodeScannerViewModel()
    @State private var scannedProduct: ScannedProduct?
    @State private var isLookingUp = false
    @State private var lookupError: FoodDatabaseError?
    @State private var showingProductSheet = false
    @State private var showingManualEntry = false

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            if viewModel.isCameraAuthorized {
                // Scanner content
                scannerContent
            } else {
                // Permission denied
                permissionDeniedView
            }

            // Loading overlay
            if isLookingUp {
                lookupOverlay
            }
        }
        .onAppear {
            viewModel.setupSession()
            viewModel.startSession()
            viewModel.onBarcodeDetected = handleBarcodeDetected
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .sheet(isPresented: $showingProductSheet) {
            if let product = scannedProduct {
                ScannedProductSheet(
                    product: product,
                    onAdd: { servings in
                        addToMeal(product: product, servings: servings)
                    },
                    onScanAgain: {
                        showingProductSheet = false
                        resetScanner()
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .alert("Product Not Found", isPresented: .init(
            get: { lookupError != nil },
            set: { if !$0 { lookupError = nil } }
        )) {
            Button("Try Again") {
                resetScanner()
            }
            Button("Enter Manually") {
                lookupError = nil
                showingManualEntry = true
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(lookupError?.errorDescription ?? "Unable to find this product")
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualBarcodeEntryView()
        }
    }

    // MARK: - Scanner Content

    private var scannerContent: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview
                CameraPreviewView(session: viewModel.session)
                    .ignoresSafeArea()

                // Dimmed overlay with cutout
                scannerOverlay(geometry: geometry)

                // UI overlay
                VStack(spacing: 0) {
                    // Top bar
                    topBar
                        .padding(.top, geometry.safeAreaInsets.top)

                    Spacer()

                    // Scanning indicator
                    scanningIndicator

                    Spacer()

                    // Bottom controls
                    bottomControls
                        .padding(.bottom, geometry.safeAreaInsets.bottom + FuelSpacing.lg)
                }
            }
        }
    }

    // MARK: - Scanner Overlay

    private func scannerOverlay(geometry: GeometryProxy) -> some View {
        let scannerWidth: CGFloat = min(geometry.size.width - 80, 300)
        let scannerHeight: CGFloat = scannerWidth * 0.6

        return ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            // Clear cutout for scanner area
            Rectangle()
                .fill(.clear)
                .frame(width: scannerWidth, height: scannerHeight)
                .background(
                    Color.black.opacity(0.01) // Nearly invisible but tappable
                )

            // Scanner frame
            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    // Corner brackets
                    ScannerFrame(width: scannerWidth, height: scannerHeight)

                    // Scanning line animation
                    if viewModel.isSessionRunning && !isLookingUp {
                        ScanningLine(width: scannerWidth - 20)
                    }
                }

                Spacer()
            }
        }
        .compositingGroup()
        .mask(
            ZStack {
                Rectangle()
                    .fill(Color.white)

                Rectangle()
                    .fill(Color.black)
                    .frame(width: scannerWidth, height: scannerHeight)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        )
        .overlay(
            // Scanner frame on top of mask
            ScannerFrame(width: scannerWidth, height: scannerHeight)
        )
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Close button
            Button {
                FuelHaptics.shared.tap()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Scan Barcode")
                .font(FuelTypography.headline)
                .foregroundStyle(.white)

            Spacer()

            // Torch button
            Button {
                viewModel.toggleTorch()
            } label: {
                Image(systemName: viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(viewModel.isTorchOn ? FuelColors.gold : .white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, FuelSpacing.screenHorizontal)
        .padding(.top, FuelSpacing.md)
    }

    // MARK: - Scanning Indicator

    private var scanningIndicator: some View {
        VStack(spacing: FuelSpacing.md) {
            if let barcode = viewModel.scannedBarcode {
                HStack(spacing: FuelSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(FuelColors.success)

                    Text("Found: \(barcode)")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, FuelSpacing.md)
                .padding(.vertical, FuelSpacing.sm)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            } else {
                Text("Position barcode in the frame")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.top, 200)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: FuelSpacing.lg) {
            // Instructions
            VStack(spacing: FuelSpacing.xs) {
                Text("Scan the barcode on food packaging")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(.white.opacity(0.8))

                Text("UPC, EAN, and QR codes supported")
                    .font(FuelTypography.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .multilineTextAlignment(.center)

            // Manual entry button
            Button {
                FuelHaptics.shared.tap()
                showingManualEntry = true
            } label: {
                HStack(spacing: FuelSpacing.sm) {
                    Image(systemName: "keyboard")
                    Text("Enter Barcode Manually")
                }
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, FuelSpacing.lg)
                .padding(.vertical, FuelSpacing.sm)
                .background(.ultraThinMaterial.opacity(0.5))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, FuelSpacing.screenHorizontal)
    }

    // MARK: - Lookup Overlay

    private var lookupOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: FuelSpacing.lg) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: FuelColors.primary))
                    .scaleEffect(1.5)

                Text("Looking up product...")
                    .font(FuelTypography.headline)
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        VStack(spacing: FuelSpacing.xl) {
            Spacer()

            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: FuelSpacing.sm) {
                Text("Camera Access Required")
                    .font(FuelTypography.title2)
                    .foregroundStyle(.white)

                Text("Fuel needs camera access to scan barcodes on food packaging.")
                    .font(FuelTypography.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, FuelSpacing.xl)

            FuelButton("Open Settings") {
                viewModel.openSettings()
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)

            Button {
                FuelHaptics.shared.tap()
                dismiss()
            } label: {
                Text("Cancel")
                    .font(FuelTypography.body)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
    }

    // MARK: - Actions

    private func handleBarcodeDetected(_ barcode: String) {
        isLookingUp = true

        Task {
            do {
                let product = try await FoodDatabaseService.shared.lookupBarcode(barcode)

                await MainActor.run {
                    isLookingUp = false
                    scannedProduct = product
                    showingProductSheet = true
                    FuelHaptics.shared.success()
                }
            } catch let error as FoodDatabaseError {
                await MainActor.run {
                    isLookingUp = false
                    lookupError = error
                    FuelHaptics.shared.error()
                }
            } catch {
                await MainActor.run {
                    isLookingUp = false
                    lookupError = .networkError(error)
                    FuelHaptics.shared.error()
                }
            }
        }
    }

    private func resetScanner() {
        viewModel.resetScanner()
        scannedProduct = nil
        lookupError = nil
    }

    private func addToMeal(product: ScannedProduct, servings: Double) {
        // Create food item and add to current meal
        let foodItem = product.toFoodItem(servings: servings)
        // TODO: Add to meal via data manager
        FuelHaptics.shared.success()
        showingProductSheet = false
        dismiss()
    }
}

// MARK: - Scanner Frame

struct ScannerFrame: View {
    let width: CGFloat
    let height: CGFloat
    let cornerLength: CGFloat = 30
    let lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            // Top-left corner
            CornerBracket(cornerLength: cornerLength, lineWidth: lineWidth)
                .position(x: (width / 2) - width / 2 + cornerLength / 2,
                         y: (height / 2) - height / 2 + cornerLength / 2)

            // Top-right corner
            CornerBracket(cornerLength: cornerLength, lineWidth: lineWidth)
                .rotationEffect(.degrees(90))
                .position(x: (width / 2) + width / 2 - cornerLength / 2,
                         y: (height / 2) - height / 2 + cornerLength / 2)

            // Bottom-left corner
            CornerBracket(cornerLength: cornerLength, lineWidth: lineWidth)
                .rotationEffect(.degrees(-90))
                .position(x: (width / 2) - width / 2 + cornerLength / 2,
                         y: (height / 2) + height / 2 - cornerLength / 2)

            // Bottom-right corner
            CornerBracket(cornerLength: cornerLength, lineWidth: lineWidth)
                .rotationEffect(.degrees(180))
                .position(x: (width / 2) + width / 2 - cornerLength / 2,
                         y: (height / 2) + height / 2 - cornerLength / 2)
        }
        .frame(width: width, height: height)
    }
}

struct CornerBracket: View {
    let cornerLength: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: cornerLength))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: cornerLength, y: 0))
        }
        .stroke(FuelColors.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        .frame(width: cornerLength, height: cornerLength)
    }
}

// MARK: - Scanning Line Animation

struct ScanningLine: View {
    let width: CGFloat
    @State private var offset: CGFloat = -60

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        FuelColors.primary.opacity(0),
                        FuelColors.primary.opacity(0.8),
                        FuelColors.primary.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: 2)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                ) {
                    offset = 60
                }
            }
    }
}

// MARK: - Preview

#Preview {
    BarcodeScannerView()
}

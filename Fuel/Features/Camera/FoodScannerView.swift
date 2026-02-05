import SwiftUI
import SwiftData
import PhotosUI

/// Food Scanner View
/// Main entry point for food scanning - camera, photo library, or barcode

struct FoodScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var selectedTab = 0
    @State private var capturedImage: UIImage?
    @State private var showingResults = false
    @State private var showingNotFoodAlert = false
    @State private var scannedProduct: ScannedProduct?
    @State private var showingProductSheet = false

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar

                // Tab selector
                tabSelector
                    .padding(.top, FuelSpacing.sm)

                // Content
                TabView(selection: $selectedTab) {
                    // Camera tab
                    CameraContentView(
                        onCapture: { image in
                            capturedImage = image
                            showingResults = true
                        }
                    )
                    .tag(0)

                    // Barcode tab - inline scanner
                    InlineBarcodeScannerView(
                        onProductFound: { product in
                            scannedProduct = product
                            showingProductSheet = true
                        }
                    )
                    .tag(1)

                    // Library tab
                    LibraryContentView(
                        onSelect: { image in
                            capturedImage = image
                            showingResults = true
                        }
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .fullScreenCover(isPresented: $showingResults) {
            if let image = capturedImage {
                PhotoReviewView(
                    image: image,
                    onRetake: {
                        showingResults = false
                        capturedImage = nil
                    },
                    onConfirm: {
                        showingResults = false
                        dismiss()
                    },
                    onNotFood: {
                        showingResults = false
                        capturedImage = nil
                        showingNotFoodAlert = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingProductSheet) {
            if let product = scannedProduct {
                ScannedProductSheet(
                    product: product,
                    onAdd: { servings, mealType in
                        // Create food item and add to meal
                        let foodItem = product.toFoodItem(servings: servings)
                        MealService.shared.addFoodItem(foodItem, to: mealType, date: Date(), in: modelContext)
                        FuelHaptics.shared.success()
                        showingProductSheet = false
                        dismiss()
                    },
                    onScanAgain: {
                        showingProductSheet = false
                        scannedProduct = nil
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .alert("Not a Food Image", isPresented: $showingNotFoodAlert) {
            Button("Try Again", role: .cancel) { }
        } message: {
            Text("We couldn't detect any food in this image. Please try again with a photo of your meal.")
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
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

            Text("Scan Meal")
                .font(FuelTypography.headline)
                .foregroundStyle(.white)

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, FuelSpacing.screenHorizontal)
        .padding(.top, FuelSpacing.md)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: FuelSpacing.xxs) {
            tabButton(title: "Camera", icon: "camera.fill", tag: 0)
            tabButton(title: "Barcode", icon: "barcode.viewfinder", tag: 1)
            tabButton(title: "Library", icon: "photo.fill", tag: 2)
        }
        .padding(FuelSpacing.xxs)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(Capsule())
        .padding(.horizontal, FuelSpacing.screenHorizontal)
    }

    private func tabButton(title: String, icon: String, tag: Int) -> some View {
        Button {
            FuelHaptics.shared.select()
            withAnimation(FuelAnimations.spring) {
                selectedTab = tag
            }
        } label: {
            HStack(spacing: FuelSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))

                Text(title)
                    .font(FuelTypography.subheadlineMedium)
            }
            .foregroundStyle(selectedTab == tag ? .black : .white)
            .padding(.horizontal, FuelSpacing.md)
            .padding(.vertical, FuelSpacing.sm)
            .background(selectedTab == tag ? FuelColors.primary : .clear)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Camera Content View

struct CameraContentView: View {
    let onCapture: (UIImage) -> Void

    @State private var viewModel = CameraViewModel()

    var body: some View {
        ZStack {
            if viewModel.isCameraAuthorized {
                // Camera preview
                CameraPreviewView(session: viewModel.session)
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    // Guidance frame
                    guidanceFrame

                    Spacer()

                    // Capture button
                    captureButton
                        .padding(.bottom, FuelSpacing.xxl)
                }
            } else {
                // Permission needed
                permissionView
            }
        }
        .onAppear {
            viewModel.setupSession()
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onChange(of: viewModel.capturedImage) { _, image in
            if let image {
                onCapture(image)
                viewModel.capturedImage = nil
            }
        }
    }

    private var guidanceFrame: some View {
        VStack(spacing: FuelSpacing.lg) {
            // Scanning frame with red corner brackets
            ScannerFrameView(size: 280, cornerLength: 40, lineWidth: 4)
                .foregroundStyle(FuelColors.primary)

            VStack(spacing: FuelSpacing.xs) {
                Text("Position your meal in the frame")
                    .font(FuelTypography.headline)
                    .foregroundStyle(.white)

                Text("Make sure the food is well-lit")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var captureButton: some View {
        Button {
            viewModel.capturePhoto()
        } label: {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 72, height: 72)

                Circle()
                    .fill(.white)
                    .frame(width: 60, height: 60)
                    .scaleEffect(viewModel.isCapturing ? 0.9 : 1.0)
            }
        }
        .disabled(viewModel.isCapturing)
        .animation(FuelAnimations.springQuick, value: viewModel.isCapturing)
    }

    private var permissionView: some View {
        VStack(spacing: FuelSpacing.lg) {
            Image(systemName: "camera.fill")
                .font(.system(size: 50))
                .foregroundStyle(.white.opacity(0.5))

            Text("Camera access needed")
                .font(FuelTypography.headline)
                .foregroundStyle(.white)

            Button {
                viewModel.openSettings()
            } label: {
                Text("Open Settings")
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.primary)
            }
        }
    }
}

// MARK: - Inline Barcode Scanner View

struct InlineBarcodeScannerView: View {
    let onProductFound: (ScannedProduct) -> Void

    @State private var viewModel = BarcodeScannerViewModel()
    @State private var isLookingUp = false
    @State private var lookupError: String?
    @State private var showingError = false

    var body: some View {
        ZStack {
            if viewModel.isCameraAuthorized {
                // Camera preview
                CameraPreviewView(session: viewModel.session)
                    .ignoresSafeArea()

                // Scanner overlay
                VStack {
                    Spacer()

                    // Scanner frame
                    ZStack {
                        // Corner brackets
                        ScannerFrameView(size: 280, cornerLength: 40, lineWidth: 4)
                            .foregroundStyle(FuelColors.primary)

                        // Scanning line
                        if viewModel.isSessionRunning && !isLookingUp {
                            ScanningLineView()
                        }
                    }

                    // Instructions
                    VStack(spacing: FuelSpacing.xs) {
                        Text("Position barcode in the frame")
                            .font(FuelTypography.headline)
                            .foregroundStyle(.white)

                        Text("UPC, EAN, and QR codes supported")
                            .font(FuelTypography.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.top, FuelSpacing.lg)

                    Spacer()
                }

                // Loading overlay
                if isLookingUp {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()

                    VStack(spacing: FuelSpacing.md) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.3)

                        Text("Looking up product...")
                            .font(FuelTypography.subheadline)
                            .foregroundStyle(.white)
                    }
                }
            } else {
                // Permission view
                VStack(spacing: FuelSpacing.lg) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("Camera access needed")
                        .font(FuelTypography.headline)
                        .foregroundStyle(.white)

                    Button {
                        viewModel.openSettings()
                    } label: {
                        Text("Open Settings")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.primary)
                    }
                }
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
        .alert("Product Not Found", isPresented: $showingError) {
            Button("Try Again", role: .cancel) {
                viewModel.resetScanner()
            }
        } message: {
            Text(lookupError ?? "Unable to find this product in our database.")
        }
    }

    private func handleBarcodeDetected(_ barcode: String) {
        isLookingUp = true
        FuelHaptics.shared.success()

        Task {
            do {
                let product = try await FoodDatabaseService.shared.lookupBarcode(barcode)
                await MainActor.run {
                    isLookingUp = false
                    onProductFound(product)
                }
            } catch {
                await MainActor.run {
                    isLookingUp = false
                    lookupError = "We couldn't find this product. Please try again or add it manually."
                    showingError = true
                    FuelHaptics.shared.error()
                }
            }
        }
    }
}

// MARK: - Scanning Line Animation

struct ScanningLineView: View {
    @State private var offset: CGFloat = -100

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        FuelColors.primary.opacity(0),
                        FuelColors.primary,
                        FuelColors.primary.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 250, height: 2)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = 100
                }
            }
    }
}

// MARK: - Library Content View

struct LibraryContentView: View {
    let onSelect: (UIImage) -> Void

    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: FuelSpacing.xl) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.5))

            Text("Select from Library")
                .font(FuelTypography.headline)
                .foregroundStyle(.white)

            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: FuelSpacing.sm) {
                    Image(systemName: "photo.stack")
                    Text("Choose Photo")
                }
                .font(FuelTypography.headline)
                .foregroundStyle(.black)
                .padding(.horizontal, FuelSpacing.xl)
                .padding(.vertical, FuelSpacing.md)
                .background(FuelColors.primary)
                .clipShape(Capsule())
            }
            .onChange(of: selectedItem) { _, item in
                loadImage(from: item)
            }

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }

            Spacer()
        }
    }

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }

        isLoading = true

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    isLoading = false
                    onSelect(image)
                    FuelHaptics.shared.success()
                }
            } else {
                await MainActor.run {
                    isLoading = false
                    FuelHaptics.shared.error()
                }
            }
        }
    }
}

// MARK: - Scanner Frame View

/// Corner bracket scanning frame
struct ScannerFrameView: View {
    let size: CGFloat
    let cornerLength: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            // Top-left corner
            CornerBracket(rotation: 0)
                .position(x: cornerLength / 2, y: cornerLength / 2)

            // Top-right corner
            CornerBracket(rotation: 90)
                .position(x: size - cornerLength / 2, y: cornerLength / 2)

            // Bottom-right corner
            CornerBracket(rotation: 180)
                .position(x: size - cornerLength / 2, y: size - cornerLength / 2)

            // Bottom-left corner
            CornerBracket(rotation: 270)
                .position(x: cornerLength / 2, y: size - cornerLength / 2)
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func CornerBracket(rotation: Double) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: cornerLength))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: cornerLength, y: 0))
        }
        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        .frame(width: cornerLength, height: cornerLength)
        .rotationEffect(.degrees(rotation))
    }
}

#Preview {
    FoodScannerView()
        .environment(AppState())
}

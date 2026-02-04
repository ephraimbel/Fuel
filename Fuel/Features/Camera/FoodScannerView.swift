import SwiftUI
import PhotosUI

/// Food Scanner View
/// Main entry point for food scanning - camera, photo library, or barcode

struct FoodScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var selectedTab = 0
    @State private var capturedImage: UIImage?
    @State private var showingResults = false
    @State private var showingBarcodeScanner = false

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

                    // Barcode tab
                    BarcodeContentView(
                        onScanBarcode: {
                            showingBarcodeScanner = true
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
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView()
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
        VStack(spacing: FuelSpacing.md) {
            RoundedRectangle(cornerRadius: FuelSpacing.radiusLg, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 3, dash: [10, 5]))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 280, height: 280)

            Text("Position your meal in the frame")
                .font(FuelTypography.subheadline)
                .foregroundStyle(.white.opacity(0.8))
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

// MARK: - Barcode Content View

struct BarcodeContentView: View {
    let onScanBarcode: () -> Void

    var body: some View {
        VStack(spacing: FuelSpacing.xl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .stroke(FuelColors.primary.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)

                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 50))
                    .foregroundStyle(.white.opacity(0.8))
            }

            // Text
            VStack(spacing: FuelSpacing.sm) {
                Text("Scan Barcode")
                    .font(FuelTypography.headline)
                    .foregroundStyle(.white)

                Text("Scan the barcode on food packaging\nfor instant nutrition info")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            // Scan button
            Button {
                FuelHaptics.shared.tap()
                onScanBarcode()
            } label: {
                HStack(spacing: FuelSpacing.sm) {
                    Image(systemName: "viewfinder")
                    Text("Start Scanning")
                }
                .font(FuelTypography.headline)
                .foregroundStyle(.black)
                .padding(.horizontal, FuelSpacing.xl)
                .padding(.vertical, FuelSpacing.md)
                .background(FuelColors.primary)
                .clipShape(Capsule())
            }

            // Supported formats
            HStack(spacing: FuelSpacing.sm) {
                Text("Supports:")
                    .font(FuelTypography.caption)
                    .foregroundStyle(.white.opacity(0.5))

                ForEach(["UPC", "EAN", "QR"], id: \.self) { format in
                    Text(format)
                        .font(FuelTypography.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, FuelSpacing.sm)
                        .padding(.vertical, FuelSpacing.xxxs)
                        .background(.white.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            Spacer()
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

#Preview {
    FoodScannerView()
        .environment(AppState())
}

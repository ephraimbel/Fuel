import SwiftUI
import AVFoundation

/// Camera View
/// Full camera capture interface for food photo scanning

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CameraViewModel()
    @State private var showingPhotoReview = false

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            if viewModel.isCameraAuthorized {
                // Camera preview
                cameraContent
            } else {
                // Permission denied
                permissionDeniedView
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
            if image != nil {
                showingPhotoReview = true
            }
        }
        .fullScreenCover(isPresented: $showingPhotoReview) {
            if let image = viewModel.capturedImage {
                PhotoReviewView(
                    image: image,
                    onRetake: {
                        showingPhotoReview = false
                        viewModel.retakePhoto()
                    },
                    onConfirm: {
                        showingPhotoReview = false
                        dismiss()
                    }
                )
            }
        }
    }

    // MARK: - Camera Content

    private var cameraContent: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview
                CameraPreviewView(session: viewModel.session)
                    .ignoresSafeArea()

                // Overlay UI
                VStack(spacing: 0) {
                    // Top bar
                    topBar
                        .padding(.top, geometry.safeAreaInsets.top)

                    Spacer()

                    // Guidance overlay
                    guidanceOverlay

                    Spacer()

                    // Bottom controls
                    bottomControls
                        .padding(.bottom, geometry.safeAreaInsets.bottom + FuelSpacing.lg)
                }
            }
        }
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

            // Flash toggle
            Button {
                viewModel.toggleFlash()
            } label: {
                Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(viewModel.isFlashOn ? FuelColors.gold : .white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, FuelSpacing.screenHorizontal)
        .padding(.top, FuelSpacing.md)
    }

    // MARK: - Guidance Overlay

    private var guidanceOverlay: some View {
        VStack(spacing: FuelSpacing.md) {
            // Scanning frame
            RoundedRectangle(cornerRadius: FuelSpacing.radiusLg, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 3, dash: [10, 5]))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 280, height: 280)

            // Instructions
            VStack(spacing: FuelSpacing.xs) {
                Text("Position your meal in the frame")
                    .font(FuelTypography.headline)
                    .foregroundStyle(.white)

                Text("Make sure the food is well-lit and visible")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, FuelSpacing.xl)
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(alignment: .center, spacing: FuelSpacing.xxl) {
            // Gallery button
            Button {
                FuelHaptics.shared.tap()
                // Open photo picker
            } label: {
                RoundedRectangle(cornerRadius: FuelSpacing.radiusSm, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    )
            }

            // Capture button
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
                        .animation(FuelAnimations.springQuick, value: viewModel.isCapturing)
                }
            }
            .disabled(viewModel.isCapturing)

            // Tips button
            Button {
                FuelHaptics.shared.tap()
                // Show tips
            } label: {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "lightbulb")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    )
            }
        }
        .padding(.horizontal, FuelSpacing.screenHorizontal)
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        VStack(spacing: FuelSpacing.xl) {
            Spacer()

            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: FuelSpacing.sm) {
                Text("Camera Access Required")
                    .font(FuelTypography.title2)
                    .foregroundStyle(.white)

                Text("Fuel needs camera access to scan your meals and track calories automatically.")
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
}

#Preview {
    CameraView()
}

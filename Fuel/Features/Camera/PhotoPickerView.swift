import SwiftUI
import PhotosUI

/// Photo Picker View
/// Allows user to select a photo from their library for analysis

struct PhotoPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isLoading = false

    let onImageSelected: (UIImage) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                FuelColors.background
                    .ignoresSafeArea()

                if let image = selectedImage {
                    // Show selected image
                    selectedImageView(image)
                } else {
                    // Photo picker
                    photoPickerContent
                }

                if isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("Choose Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        FuelHaptics.shared.tap()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Photo Picker Content

    private var photoPickerContent: some View {
        VStack(spacing: FuelSpacing.xl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(FuelColors.primaryLight)
                    .frame(width: 100, height: 100)

                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 40))
                    .foregroundStyle(FuelColors.primary)
            }

            // Text
            VStack(spacing: FuelSpacing.sm) {
                Text("Select a Food Photo")
                    .font(FuelTypography.title2)
                    .foregroundStyle(FuelColors.textPrimary)

                Text("Choose a photo of your meal from your library")
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, FuelSpacing.xl)

            // Photo picker button
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: FuelSpacing.sm) {
                    Image(systemName: "photo.stack")
                    Text("Choose from Library")
                }
                .font(FuelTypography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FuelSpacing.md)
                .background(FuelColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .onChange(of: selectedItem) { _, newItem in
                loadImage(from: newItem)
            }

            Spacer()
        }
    }

    // MARK: - Selected Image View

    private func selectedImageView(_ image: UIImage) -> some View {
        VStack(spacing: 0) {
            // Image preview
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Actions
            VStack(spacing: FuelSpacing.md) {
                HStack(spacing: FuelSpacing.md) {
                    // Choose different
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text("Choose Different")
                            .font(FuelTypography.headline)
                            .foregroundStyle(FuelColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FuelSpacing.md)
                            .background(FuelColors.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
                    }

                    // Use this photo
                    Button {
                        FuelHaptics.shared.tap()
                        onImageSelected(image)
                        dismiss()
                    } label: {
                        HStack(spacing: FuelSpacing.xs) {
                            Image(systemName: "sparkles")
                            Text("Analyze")
                        }
                        .font(FuelTypography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FuelSpacing.md)
                        .background(FuelColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
                    }
                }
            }
            .padding(FuelSpacing.screenHorizontal)
            .padding(.bottom, FuelSpacing.xl)
            .background(FuelColors.surface)
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
    }

    // MARK: - Image Loading

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }

        isLoading = true

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                    isLoading = false
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
    PhotoPickerView { _ in }
}

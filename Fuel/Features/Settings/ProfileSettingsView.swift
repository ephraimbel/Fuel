import SwiftUI
import SwiftData
import PhotosUI

/// Profile Settings View
/// Edit user profile information

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var displayName = ""
    @State private var email = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isSaving = false
    @State private var hasChanges = false
    @State private var isLoaded = false

    var body: some View {
        ScrollView {
            VStack(spacing: FuelSpacing.xl) {
                // Profile photo
                profilePhotoSection

                // Name field
                nameSection

                // Email field
                emailSection

                // Connected accounts
                connectedAccountsSection
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
        }
        .background(FuelColors.background)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if hasChanges {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
                }
            }
        }
        .onChange(of: selectedPhoto) { _, item in
            loadImage(from: item)
        }
        .onAppear {
            loadUserData()
        }
    }

    // MARK: - Data Loading

    private func loadUserData() {
        guard !isLoaded else { return }

        let descriptor = FetchDescriptor<User>()
        guard let user = try? modelContext.fetch(descriptor).first else { return }

        displayName = user.name
        email = user.email ?? ""

        // Load profile image from avatar URL if it's a local file path
        if let avatarPath = user.avatarURL,
           let imageData = FileManager.default.contents(atPath: avatarPath),
           let image = UIImage(data: imageData) {
            profileImage = image
        }

        isLoaded = true
    }

    // MARK: - Profile Photo Section

    private var profilePhotoSection: some View {
        VStack(spacing: FuelSpacing.md) {
            // Photo
            ZStack(alignment: .bottomTrailing) {
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(FuelColors.primaryLight)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(initials)
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(FuelColors.primary)
                        )
                }

                // Edit button
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(FuelColors.primary)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(FuelColors.background, lineWidth: 3)
                        )
                }
            }

            // Remove photo button
            if profileImage != nil {
                Button {
                    profileImage = nil
                    hasChanges = true
                    FuelHaptics.shared.tap()
                } label: {
                    Text("Remove Photo")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.error)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FuelSpacing.lg)
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("NAME")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            TextField("Your name", text: $displayName)
                .font(FuelTypography.body)
                .padding(FuelSpacing.md)
                .background(FuelColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
                .onChange(of: displayName) { _, _ in
                    hasChanges = true
                }
        }
    }

    // MARK: - Email Section

    private var emailSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("EMAIL")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            HStack {
                Text(email)
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textSecondary)

                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(FuelColors.success)
            }
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))

            Text("Email is managed through your Apple ID")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
        }
    }

    // MARK: - Connected Accounts

    private var connectedAccountsSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("CONNECTED ACCOUNTS")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                // Apple ID
                HStack(spacing: FuelSpacing.md) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 20))
                        .foregroundStyle(FuelColors.textPrimary)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                        Text("Apple ID")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("Connected")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.success)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(FuelColors.success)
                }
                .padding(FuelSpacing.md)

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                // Health app
                HStack(spacing: FuelSpacing.md) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.red)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                        Text("Apple Health")
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("Sync weight and nutrition")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                        .tint(FuelColors.primary)
                }
                .padding(FuelSpacing.md)
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Computed Properties

    private var initials: String {
        let components = displayName.split(separator: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }

    // MARK: - Actions

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    profileImage = image
                    hasChanges = true
                    FuelHaptics.shared.success()
                }
            }
        }
    }

    private func saveProfile() {
        isSaving = true
        FuelHaptics.shared.tap()

        let descriptor = FetchDescriptor<User>()
        guard let user = try? modelContext.fetch(descriptor).first else {
            isSaving = false
            FuelHaptics.shared.error()
            return
        }

        // Update user name
        user.name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        user.lastActiveAt = Date()

        // Save profile image to documents directory
        if let image = profileImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let avatarPath = documentsPath.appendingPathComponent("profile_avatar.jpg")

            do {
                try imageData.write(to: avatarPath)
                user.avatarURL = avatarPath.path
            } catch {
                // Log but don't fail the save
                #if DEBUG
                print("Failed to save profile image: \(error)")
                #endif
            }
        } else if profileImage == nil {
            // User removed their profile photo
            if let existingPath = user.avatarURL {
                try? FileManager.default.removeItem(atPath: existingPath)
            }
            user.avatarURL = nil
        }

        // Persist changes
        do {
            try modelContext.save()
            isSaving = false
            hasChanges = false
            FuelHaptics.shared.success()
        } catch {
            isSaving = false
            FuelHaptics.shared.error()
            #if DEBUG
            print("Failed to save profile: \(error)")
            #endif
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileSettingsView()
    }
}

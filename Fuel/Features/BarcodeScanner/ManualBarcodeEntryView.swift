import SwiftUI
import SwiftData

/// Manual Barcode Entry View
/// Allows users to type a barcode number manually

struct ManualBarcodeEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var barcodeText = ""
    @State private var isLookingUp = false
    @State private var scannedProduct: ScannedProduct?
    @State private var lookupError: FoodDatabaseError?
    @State private var showingProductSheet = false

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                FuelColors.background
                    .ignoresSafeArea()

                VStack(spacing: FuelSpacing.xl) {
                    Spacer()

                    // Icon
                    ZStack {
                        Circle()
                            .fill(FuelColors.primaryLight)
                            .frame(width: 100, height: 100)

                        Image(systemName: "barcode")
                            .font(.system(size: 40))
                            .foregroundStyle(FuelColors.primary)
                    }

                    // Title
                    VStack(spacing: FuelSpacing.sm) {
                        Text("Enter Barcode")
                            .font(FuelTypography.title2)
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("Type the numbers below the barcode")
                            .font(FuelTypography.body)
                            .foregroundStyle(FuelColors.textSecondary)
                    }

                    // Text field
                    VStack(spacing: FuelSpacing.sm) {
                        TextField("", text: $barcodeText)
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .focused($isTextFieldFocused)
                            .padding(FuelSpacing.md)
                            .background(FuelColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
                            .overlay(
                                RoundedRectangle(cornerRadius: FuelSpacing.radiusMd)
                                    .stroke(
                                        isTextFieldFocused ? FuelColors.primary : FuelColors.border,
                                        lineWidth: isTextFieldFocused ? 2 : 1
                                    )
                            )

                        // Character count
                        HStack {
                            Text("\(barcodeText.count) digits")
                                .font(FuelTypography.caption)
                                .foregroundStyle(FuelColors.textTertiary)

                            Spacer()

                            if isValidBarcode {
                                HStack(spacing: FuelSpacing.xxs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(FuelColors.success)
                                    Text("Valid format")
                                        .foregroundStyle(FuelColors.success)
                                }
                                .font(FuelTypography.caption)
                            }
                        }
                    }
                    .padding(.horizontal, FuelSpacing.screenHorizontal)

                    // Common formats
                    VStack(alignment: .leading, spacing: FuelSpacing.sm) {
                        Text("Common barcode formats:")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)

                        HStack(spacing: FuelSpacing.md) {
                            formatBadge("UPC-A (12)")
                            formatBadge("EAN-13 (13)")
                            formatBadge("EAN-8 (8)")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, FuelSpacing.screenHorizontal)

                    Spacer()

                    // Search button
                    FuelButton("Search Product", style: .primary) {
                        lookupBarcode()
                    }
                    .disabled(!isValidBarcode || isLookingUp)
                    .padding(.horizontal, FuelSpacing.screenHorizontal)
                    .padding(.bottom, FuelSpacing.xl)
                }

                // Loading overlay
                if isLookingUp {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: FuelSpacing.md) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: FuelColors.primary))

                            Text("Searching...")
                                .font(FuelTypography.subheadline)
                                .foregroundStyle(FuelColors.textPrimary)
                        }
                        .padding(FuelSpacing.xl)
                        .background(FuelColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusLg))
                    }
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        FuelHaptics.shared.tap()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isTextFieldFocused = false
                        }
                    }
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
            .alert("Product Not Found", isPresented: .init(
                get: { lookupError != nil },
                set: { if !$0 { lookupError = nil } }
            )) {
                Button("Try Again") {
                    barcodeText = ""
                    isTextFieldFocused = true
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(lookupError?.errorDescription ?? "Unable to find this product")
            }
            .sheet(isPresented: $showingProductSheet) {
                if let product = scannedProduct {
                    ScannedProductSheet(
                        product: product,
                        onAdd: { servings, mealType in
                            addToMeal(product: product, servings: servings, mealType: mealType)
                        },
                        onScanAgain: {
                            showingProductSheet = false
                            barcodeText = ""
                            isTextFieldFocused = true
                        }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isValidBarcode: Bool {
        let count = barcodeText.count
        // UPC-A: 12, UPC-E: 8, EAN-13: 13, EAN-8: 8
        return (count == 8 || count == 12 || count == 13) && barcodeText.allSatisfy { $0.isNumber }
    }

    // MARK: - Views

    private func formatBadge(_ text: String) -> some View {
        Text(text)
            .font(FuelTypography.caption)
            .foregroundStyle(FuelColors.textSecondary)
            .padding(.horizontal, FuelSpacing.sm)
            .padding(.vertical, FuelSpacing.xxs)
            .background(FuelColors.surfaceSecondary)
            .clipShape(Capsule())
    }

    // MARK: - Actions

    private func lookupBarcode() {
        guard isValidBarcode else { return }

        isTextFieldFocused = false
        isLookingUp = true
        FuelHaptics.shared.tap()

        Task {
            do {
                let product = try await FoodDatabaseService.shared.lookupBarcode(barcodeText)

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

    private func addToMeal(product: ScannedProduct, servings: Double, mealType: MealType) {
        // Create food item from scanned product
        let foodItem = product.toFoodItem(servings: servings)

        // Add to meal using MealService
        MealService.shared.addFoodItem(foodItem, to: mealType, date: Date(), in: modelContext)

        FuelHaptics.shared.success()
        showingProductSheet = false
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    ManualBarcodeEntryView()
}

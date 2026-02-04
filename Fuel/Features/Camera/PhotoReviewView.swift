import SwiftUI

/// Photo Review View
/// Allows user to review captured photo before analyzing

struct PhotoReviewView: View {
    let image: UIImage
    let onRetake: () -> Void
    let onConfirm: () -> Void

    @State private var isAnalyzing = false
    @State private var analysisResult: MealAnalysisResult?
    @State private var analysisError: AIVisionError?
    @State private var selectedMealType: MealType = .suggested()

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Image preview
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom panel
                bottomPanel
            }

            // Analysis overlay
            if isAnalyzing {
                analysisOverlay
            }

            // Results overlay
            if let result = analysisResult {
                AnalysisResultsView(
                    result: result,
                    mealType: selectedMealType,
                    onMealTypeChange: { selectedMealType = $0 },
                    onConfirm: {
                        // Save meal and dismiss
                        FuelHaptics.shared.success()
                        onConfirm()
                    },
                    onRetake: {
                        analysisResult = nil
                        onRetake()
                    }
                )
            }
        }
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: FuelSpacing.lg) {
            // Error message
            if let error = analysisError {
                HStack(spacing: FuelSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(FuelColors.error)

                    Text(error.localizedDescription)
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(.white)
                }
                .padding(FuelSpacing.md)
                .background(FuelColors.error.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            }

            // Action buttons
            HStack(spacing: FuelSpacing.md) {
                // Retake button
                Button {
                    FuelHaptics.shared.tap()
                    onRetake()
                } label: {
                    HStack(spacing: FuelSpacing.xs) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Retake")
                    }
                    .font(FuelTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FuelSpacing.md)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
                }

                // Analyze button
                Button {
                    analyzePhoto()
                } label: {
                    HStack(spacing: FuelSpacing.xs) {
                        Image(systemName: "sparkles")
                        Text("Analyze")
                    }
                    .font(FuelTypography.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FuelSpacing.md)
                    .background(FuelColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
                }
                .disabled(isAnalyzing)
            }
        }
        .padding(FuelSpacing.screenHorizontal)
        .padding(.bottom, FuelSpacing.xl)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Analysis Overlay

    private var analysisOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: FuelSpacing.lg) {
                // Animated icon
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(FuelColors.primary.opacity(0.3), lineWidth: 2)
                            .frame(width: CGFloat(60 + index * 30), height: CGFloat(60 + index * 30))
                            .scaleEffect(isAnalyzing ? 1.2 : 0.8)
                            .opacity(isAnalyzing ? 0 : 1)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.3),
                                value: isAnalyzing
                            )
                    }

                    Image(systemName: "sparkles")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(FuelColors.primary)
                }

                VStack(spacing: FuelSpacing.sm) {
                    Text("Analyzing your meal...")
                        .font(FuelTypography.headline)
                        .foregroundStyle(.white)

                    Text("Using AI to identify foods and estimate nutrition")
                        .font(FuelTypography.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(FuelSpacing.xl)
        }
    }

    // MARK: - Analysis

    private func analyzePhoto() {
        isAnalyzing = true
        analysisError = nil

        FuelHaptics.shared.tap()

        Task {
            do {
                let result = try await AIVisionService.shared.analyzeMeal(image: image)

                await MainActor.run {
                    isAnalyzing = false
                    analysisResult = result
                    selectedMealType = result.suggestedMealType
                    FuelHaptics.shared.success()
                }
            } catch let error as AIVisionError {
                await MainActor.run {
                    isAnalyzing = false
                    analysisError = error
                    FuelHaptics.shared.error()
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    analysisError = .networkError(error)
                    FuelHaptics.shared.error()
                }
            }
        }
    }
}

// MARK: - Analysis Results View

struct AnalysisResultsView: View {
    let result: MealAnalysisResult
    let mealType: MealType
    let onMealTypeChange: (MealType) -> Void
    let onConfirm: () -> Void
    let onRetake: () -> Void

    @State private var editingItems: [AnalyzedFoodItem]

    init(
        result: MealAnalysisResult,
        mealType: MealType,
        onMealTypeChange: @escaping (MealType) -> Void,
        onConfirm: @escaping () -> Void,
        onRetake: @escaping () -> Void
    ) {
        self.result = result
        self.mealType = mealType
        self.onMealTypeChange = onMealTypeChange
        self.onConfirm = onConfirm
        self.onRetake = onRetake
        self._editingItems = State(initialValue: result.items)
    }

    private var totalCalories: Int {
        editingItems.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.top, FuelSpacing.xl)

                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: FuelSpacing.lg) {
                        // Confidence indicator
                        confidenceIndicator

                        // Meal type selector
                        mealTypeSelector

                        // Food items
                        foodItemsList

                        // Summary
                        nutritionSummary
                    }
                    .padding(.horizontal, FuelSpacing.screenHorizontal)
                    .padding(.bottom, FuelSpacing.xxl)
                }

                // Bottom actions
                bottomActions
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: FuelSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(FuelColors.success)

            Text("Meal Analyzed!")
                .font(FuelTypography.title2)
                .foregroundStyle(.white)

            Text("Review and adjust if needed")
                .font(FuelTypography.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.bottom, FuelSpacing.lg)
    }

    // MARK: - Confidence Indicator

    private var confidenceIndicator: some View {
        HStack(spacing: FuelSpacing.sm) {
            Image(systemName: "sparkles")
                .foregroundStyle(FuelColors.primary)

            Text("AI Confidence: \(Int(result.confidence * 100))%")
                .font(FuelTypography.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()
        }
        .padding(FuelSpacing.md)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Meal Type Selector

    private var mealTypeSelector: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("Meal Type")
                .font(FuelTypography.caption)
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)

            HStack(spacing: FuelSpacing.sm) {
                ForEach(MealType.allCases, id: \.self) { type in
                    mealTypeButton(type)
                }
            }
        }
    }

    private func mealTypeButton(_ type: MealType) -> some View {
        Button {
            FuelHaptics.shared.select()
            onMealTypeChange(type)
        } label: {
            VStack(spacing: FuelSpacing.xs) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))

                Text(type.displayName)
                    .font(FuelTypography.caption)
            }
            .foregroundStyle(mealType == type ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, FuelSpacing.sm)
            .background(mealType == type ? FuelColors.primary : .white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - Food Items List

    private var foodItemsList: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("Detected Foods")
                .font(FuelTypography.caption)
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)

            ForEach(editingItems) { item in
                FoodItemRow(item: item)
            }
        }
    }

    // MARK: - Nutrition Summary

    private var nutritionSummary: some View {
        VStack(spacing: FuelSpacing.md) {
            HStack {
                Text("Total")
                    .font(FuelTypography.headline)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(totalCalories) cal")
                    .font(FuelTypography.title2)
                    .foregroundStyle(FuelColors.primary)
            }

            HStack(spacing: FuelSpacing.lg) {
                macroSummaryItem(
                    label: "Protein",
                    value: editingItems.reduce(0) { $0 + $1.protein },
                    color: FuelColors.protein
                )
                macroSummaryItem(
                    label: "Carbs",
                    value: editingItems.reduce(0) { $0 + $1.carbs },
                    color: FuelColors.carbs
                )
                macroSummaryItem(
                    label: "Fat",
                    value: editingItems.reduce(0) { $0 + $1.fat },
                    color: FuelColors.fat
                )
            }
        }
        .padding(FuelSpacing.md)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    private func macroSummaryItem(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: FuelSpacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(Int(value))g")
                .font(FuelTypography.headline)
                .foregroundStyle(.white)

            Text(label)
                .font(FuelTypography.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        HStack(spacing: FuelSpacing.md) {
            Button {
                onRetake()
            } label: {
                Text("Retake")
                    .font(FuelTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FuelSpacing.md)
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            }

            Button {
                onConfirm()
            } label: {
                HStack(spacing: FuelSpacing.xs) {
                    Image(systemName: "checkmark")
                    Text("Log Meal")
                }
                .font(FuelTypography.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FuelSpacing.md)
                .background(FuelColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            }
        }
        .padding(.horizontal, FuelSpacing.screenHorizontal)
        .padding(.vertical, FuelSpacing.lg)
        .background(.black)
    }
}

// MARK: - Food Item Row

struct FoodItemRow: View {
    let item: AnalyzedFoodItem

    var body: some View {
        HStack(spacing: FuelSpacing.md) {
            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text(item.name)
                    .font(FuelTypography.headline)
                    .foregroundStyle(.white)

                Text(item.servingSize)
                    .font(FuelTypography.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Text("\(item.calories) cal")
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(FuelColors.primary)
        }
        .padding(FuelSpacing.md)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }
}

// MARK: - MealType Extension

extension MealType {
    static func suggested(for date: Date = Date()) -> MealType {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6...10: return .breakfast
        case 11...14: return .lunch
        case 17...21: return .dinner
        default: return .snack
        }
    }
}

#Preview {
    PhotoReviewView(
        image: UIImage(systemName: "photo")!,
        onRetake: {},
        onConfirm: {}
    )
}

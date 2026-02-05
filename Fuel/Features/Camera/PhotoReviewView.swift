import SwiftUI

/// Photo Review View
/// Allows user to review captured photo before analyzing

struct PhotoReviewView: View {
    let image: UIImage
    let onRetake: () -> Void
    let onConfirm: () -> Void
    var onNotFood: (() -> Void)? = nil

    @State private var isAnalyzing = false
    @State private var analysisResult: MealAnalysisResult?
    @State private var analysisError: AIVisionError?
    @State private var selectedMealType: MealType = .suggested()

    // Paywall state
    @State private var showPaywall = false
    @State private var showLowScansWarning = false

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

            // Low scans warning banner
            if showLowScansWarning {
                lowScansWarningBanner
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(context: .scanLimit)
        }
    }

    // MARK: - Low Scans Warning Banner

    private var lowScansWarningBanner: some View {
        VStack {
            Spacer()

            HStack(spacing: FuelSpacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundStyle(FuelColors.warning)

                Text("\(FeatureGateService.shared.remainingAIScans) scans remaining this week")
                    .font(FuelTypography.subheadline)
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    FuelHaptics.shared.tap()
                    showLowScansWarning = false
                    showPaywall = true
                } label: {
                    Text("Go unlimited")
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.primary)
                }
            }
            .padding(FuelSpacing.md)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.bottom, 100) // Above bottom panel
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
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
        // Check scan limit BEFORE analyzing
        guard FeatureGateService.shared.canUseAIScan() else {
            FuelHaptics.shared.error()
            showPaywall = true
            return
        }

        isAnalyzing = true
        analysisError = nil

        FuelHaptics.shared.tap()

        Task {
            do {
                let result = try await AIVisionService.shared.analyzeMeal(image: image)

                await MainActor.run {
                    isAnalyzing = false

                    // Check if any food was detected
                    if result.items.isEmpty {
                        FuelHaptics.shared.error()
                        onNotFood?()
                    } else {
                        // Use a scan on success
                        FeatureGateService.shared.useAIScan()

                        analysisResult = result
                        selectedMealType = result.suggestedMealType
                        FuelHaptics.shared.success()

                        // Show low scans warning if applicable
                        let remaining = FeatureGateService.shared.remainingAIScans
                        if remaining > 0 && remaining <= 2 && !FeatureGateService.shared.isPremium {
                            withAnimation(FuelAnimations.spring) {
                                showLowScansWarning = true
                            }
                        }
                    }
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
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main row
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

                HStack(spacing: FuelSpacing.sm) {
                    Text("\(item.calories) cal")
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.primary)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(FuelSpacing.md)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }

            // Expanded nutrition details
            if isExpanded {
                VStack(spacing: FuelSpacing.sm) {
                    Divider()
                        .background(.white.opacity(0.2))

                    // Macros
                    HStack(spacing: FuelSpacing.md) {
                        microNutrientLabel("Protein", "\(Int(item.protein))g", FuelColors.protein)
                        microNutrientLabel("Carbs", "\(Int(item.carbs))g", FuelColors.carbs)
                        microNutrientLabel("Fat", "\(Int(item.fat))g", FuelColors.fat)
                    }

                    // Micros (if available)
                    if item.fiber != nil || item.sugar != nil || item.sodium != nil {
                        Divider()
                            .background(.white.opacity(0.2))

                        HStack(spacing: FuelSpacing.md) {
                            if let fiber = item.fiber {
                                microNutrientLabel("Fiber", "\(Int(fiber))g", .white.opacity(0.7))
                            }
                            if let sugar = item.sugar {
                                microNutrientLabel("Sugar", "\(Int(sugar))g", .white.opacity(0.7))
                            }
                            if let sodium = item.sodium {
                                microNutrientLabel("Sodium", "\(Int(sodium))mg", .white.opacity(0.7))
                            }
                        }
                    }

                    if item.saturatedFat != nil || item.cholesterol != nil {
                        HStack(spacing: FuelSpacing.md) {
                            if let satFat = item.saturatedFat {
                                microNutrientLabel("Sat Fat", "\(Int(satFat))g", .white.opacity(0.7))
                            }
                            if let cholesterol = item.cholesterol {
                                microNutrientLabel("Cholesterol", "\(Int(cholesterol))mg", .white.opacity(0.7))
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, FuelSpacing.md)
                .padding(.bottom, FuelSpacing.md)
            }
        }
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    private func microNutrientLabel(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(FuelTypography.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PhotoReviewView(
        image: UIImage(systemName: "photo")!,
        onRetake: {},
        onConfirm: {},
        onNotFood: {}
    )
}

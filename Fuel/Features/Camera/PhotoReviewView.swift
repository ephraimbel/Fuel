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
                MealResultsView(
                    image: image,
                    result: result,
                    mealType: selectedMealType,
                    onMealTypeChange: { selectedMealType = $0 },
                    onConfirm: {
                        FuelHaptics.shared.success()
                        onConfirm()
                    },
                    onFixResults: {
                        // Allow user to retake or edit
                        analysisResult = nil
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
            .padding(.bottom, 100)
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

                    if result.items.isEmpty {
                        FuelHaptics.shared.error()
                        onNotFood?()
                    } else {
                        FeatureGateService.shared.useAIScan()

                        analysisResult = result
                        selectedMealType = result.suggestedMealType
                        FuelHaptics.shared.success()

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

// MARK: - Meal Results View (Cal AI Style)

struct MealResultsView: View {
    let image: UIImage
    let result: MealAnalysisResult
    let mealType: MealType
    let onMealTypeChange: (MealType) -> Void
    let onConfirm: () -> Void
    let onFixResults: () -> Void

    @State private var servings: Int = 1
    @State private var cardOffset: CGFloat = 0

    private var totalCalories: Int {
        result.items.reduce(0) { $0 + $1.calories } * servings
    }

    private var totalProtein: Int {
        Int(result.items.reduce(0) { $0 + $1.protein }) * servings
    }

    private var totalCarbs: Int {
        Int(result.items.reduce(0) { $0 + $1.carbs }) * servings
    }

    private var totalFat: Int {
        Int(result.items.reduce(0) { $0 + $1.fat }) * servings
    }

    private var healthScore: Int {
        // Calculate health score based on macro balance
        let proteinRatio = Double(totalProtein) * 4 / max(Double(totalCalories), 1)
        let fatRatio = Double(totalFat) * 9 / max(Double(totalCalories), 1)

        var score = 5 // Base score

        // Good protein ratio (20-35%)
        if proteinRatio >= 0.20 && proteinRatio <= 0.35 {
            score += 2
        } else if proteinRatio >= 0.15 {
            score += 1
        }

        // Moderate fat (20-35%)
        if fatRatio >= 0.20 && fatRatio <= 0.35 {
            score += 2
        } else if fatRatio <= 0.40 {
            score += 1
        }

        // Calorie penalty for very high calorie meals
        if totalCalories > 800 {
            score -= 1
        }

        return min(max(score, 1), 10)
    }

    private var foodName: String {
        if result.items.count == 1 {
            return result.items[0].name
        } else if result.items.count > 1 {
            return "\(result.items[0].name) & more"
        }
        return "Analyzed Meal"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            Color.black.ignoresSafeArea()

            // Food image at top
            VStack {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.55)
                        .clipped()
                        .overlay(alignment: .top) {
                            // Top bar with Nutrition label
                            HStack {
                                Spacer()

                                Text("Nutrition")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())

                                Spacer()
                            }
                            .padding(.top, 60)
                        }
                        .overlay(alignment: .topTrailing) {
                            // Menu button
                            Button {
                                FuelHaptics.shared.tap()
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .padding(.top, 56)
                            .padding(.trailing, 16)
                        }
                }

                Spacer()
            }

            // White card from bottom
            VStack(spacing: 0) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                VStack(spacing: 20) {
                    // Meal type and name
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mealType.displayName)
                            .font(.system(size: 13))
                            .foregroundStyle(.gray)

                        HStack {
                            Text(foodName)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.black)

                            Spacer()

                            // Quantity selector
                            HStack(spacing: 0) {
                                Button {
                                    if servings > 1 {
                                        servings -= 1
                                        FuelHaptics.shared.tap()
                                    }
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(servings > 1 ? .black : .gray)
                                        .frame(width: 32, height: 32)
                                }

                                Text("\(servings)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .frame(width: 32)

                                Button {
                                    servings += 1
                                    FuelHaptics.shared.tap()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.black)
                                        .frame(width: 32, height: 32)
                                }
                            }
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    // Nutrition grid 2x2
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        NutritionGridItem(
                            icon: "flame.fill",
                            iconColor: .orange,
                            label: "Calories",
                            value: "\(totalCalories)"
                        )

                        NutritionGridItem(
                            icon: "leaf.fill",
                            iconColor: .green,
                            label: "Carbs",
                            value: "\(totalCarbs)g"
                        )

                        NutritionGridItem(
                            icon: "fish.fill",
                            iconColor: FuelColors.protein,
                            label: "Protein",
                            value: "\(totalProtein)g",
                            emoji: "🥩"
                        )

                        NutritionGridItem(
                            icon: "drop.circle.fill",
                            iconColor: FuelColors.fat,
                            label: "Fats",
                            value: "\(totalFat)g",
                            emoji: "🥑"
                        )
                    }

                    // Health score
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.pink)

                            Text("Health score")
                                .font(.system(size: 14))
                                .foregroundStyle(.gray)

                            Spacer()

                            Text("\(healthScore)/10")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.black)
                        }

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.15))

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .yellow, .orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat(healthScore) / 10.0)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(16)
                    .background(Color.gray.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Bottom buttons
                    HStack(spacing: 12) {
                        Button {
                            FuelHaptics.shared.tap()
                            onFixResults()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14))
                                Text("Fix Results")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                        }

                        Button {
                            FuelHaptics.shared.success()
                            onConfirm()
                        } label: {
                            Text("Done")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white)
                    .ignoresSafeArea(edges: .bottom)
            )
            .frame(height: UIScreen.main.bounds.height * 0.55)
        }
    }
}

// MARK: - Nutrition Grid Item

struct NutritionGridItem: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    var emoji: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let emoji {
                    Text(emoji)
                        .font(.system(size: 18))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(iconColor)
                }
            }
            .frame(width: 36, height: 36)
            .background(iconColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)

                Text(value)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

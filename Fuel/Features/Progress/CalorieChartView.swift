import SwiftUI
import Charts

/// Calorie Chart View
/// Interactive bar chart showing daily calorie intake with animations

struct CalorieChartView: View {
    let entries: [CalorieDataPoint]
    let goal: Int
    var timeRange: TimeRange = .week

    @State private var selectedEntry: CalorieDataPoint?
    @State private var lastSelectedId: UUID?
    @State private var animate = false

    private var maxCalories: Int {
        max(entries.map { $0.calories }.max() ?? 0, goal) + 200
    }

    /// Minimum width per bar so they stay readable at every range
    private var chartWidth: CGFloat? {
        let count = CGFloat(entries.count)
        switch timeRange {
        case .week:
            return nil // use available width
        case .month:
            return max(count * 16, 480)
        case .threeMonths:
            return max(count * 12, 900)
        case .year:
            return max(count * 8, 2000)
        }
    }

    private var needsScroll: Bool { chartWidth != nil }

    var body: some View {
        if #available(iOS 16.0, *) {
            chartContainer
                .onAppear {
                    guard !animate else { return }
                    triggerAnimation()
                }
                .onChange(of: entries.count) { _, newCount in
                    if newCount > 0 && !animate {
                        triggerAnimation()
                    }
                }
                .onChange(of: timeRange) { _, _ in
                    // Reset and re-animate when range changes
                    animate = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        triggerAnimation()
                    }
                }
        } else {
            customChartView
        }
    }

    // MARK: - Chart Container

    @available(iOS 16.0, *)
    @ViewBuilder
    private var chartContainer: some View {
        if needsScroll {
            ScrollView(.horizontal, showsIndicators: false) {
                swiftChartsView
                    .frame(width: chartWidth)
            }
        } else {
            swiftChartsView
        }
    }

    // MARK: - Bar Animation

    private func triggerAnimation() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15)) {
            animate = true
        }
    }

    // MARK: - Swift Charts (iOS 16+)

    @available(iOS 16.0, *)
    private var swiftChartsView: some View {
        Chart {
            // Goal line
            RuleMark(y: .value("Goal", goal))
                .foregroundStyle(FuelColors.textTertiary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .trailing, alignment: .leading) {
                    Text("Goal")
                        .font(.system(size: 9))
                        .foregroundStyle(FuelColors.textTertiary)
                        .padding(.leading, 4)
                }

            // Stacked macro bars
            ForEach(entries) { entry in
                let scale: Double = animate ? 1.0 : 0.0
                let hasMacros = entry.proteinPercent + entry.carbsPercent + entry.fatPercent > 0

                if hasMacros {
                    // Protein bar (bottom of stack)
                    BarMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Protein", Double(entry.calories) * entry.proteinPercent * scale)
                    )
                    .foregroundStyle(FuelColors.protein)
                    .cornerRadius(0)

                    // Carbs bar (middle of stack)
                    BarMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Carbs", Double(entry.calories) * entry.carbsPercent * scale)
                    )
                    .foregroundStyle(FuelColors.carbs)
                    .cornerRadius(0)

                    // Fat bar (top of stack)
                    BarMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Fat", Double(entry.calories) * entry.fatPercent * scale)
                    )
                    .foregroundStyle(FuelColors.fat)
                    .cornerRadius(6)
                } else if entry.calories > 0 {
                    // No macro breakdown — show single bar
                    BarMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Calories", Double(entry.calories) * scale)
                    )
                    .foregroundStyle(FuelColors.primary)
                    .cornerRadius(6)
                }
            }
        }
        .chartForegroundStyleScale([
            "Protein": FuelColors.protein,
            "Carbs": FuelColors.carbs,
            "Fat": FuelColors.fat
        ])
        .chartYScale(domain: 0...maxCalories)
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                if let date = value.as(Date.self) {
                    let isSelected = selectedEntry.map { Calendar.current.isDate($0.date, inSameDayAs: date) } ?? false
                    AxisValueLabel {
                        Text(xAxisLabel(for: date))
                            .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                            .foregroundStyle(isSelected ? FuelColors.primary : FuelColors.textTertiary)
                    }
                    AxisGridLine()
                        .foregroundStyle(FuelColors.surfaceSecondary)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                    .foregroundStyle(FuelColors.surfaceSecondary)
                AxisValueLabel()
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x
                                if let date: Date = proxy.value(atX: x) {
                                    let closest = entries.min(by: {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    })
                                    // Only trigger haptic when selection changes
                                    if closest?.id != lastSelectedId {
                                        lastSelectedId = closest?.id
                                        withAnimation(.easeOut(duration: 0.15)) {
                                            selectedEntry = closest
                                        }
                                        FuelHaptics.shared.select()
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedEntry = nil
                                }
                                lastSelectedId = nil
                            }
                    )
            }
        }
        .overlay(alignment: .top) {
            if let entry = selectedEntry {
                tooltipView(for: entry)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedEntry?.id)
    }

    // MARK: - Custom Chart (Fallback)

    private var customChartView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let barWidth = (width - CGFloat(entries.count - 1) * 4) / CGFloat(entries.count)

            ZStack(alignment: .bottom) {
                // Grid lines
                ForEach(0..<4, id: \.self) { i in
                    let y = height * CGFloat(i) / 3
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(FuelColors.surfaceSecondary, lineWidth: 1)
                }

                // Goal line
                let goalY = height * (1 - CGFloat(goal) / CGFloat(maxCalories))
                Path { path in
                    path.move(to: CGPoint(x: 0, y: goalY))
                    path.addLine(to: CGPoint(x: width, y: goalY))
                }
                .stroke(FuelColors.textTertiary, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))

                // Stacked macro bars
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(entries) { entry in
                        let barHeight = height * CGFloat(entry.calories) / CGFloat(maxCalories)
                        let hasMacros = entry.proteinPercent + entry.carbsPercent + entry.fatPercent > 0

                        VStack(spacing: FuelSpacing.xxxs) {
                            if hasMacros {
                                // Stacked bar
                                VStack(spacing: 0) {
                                    // Fat (top)
                                    Rectangle()
                                        .fill(FuelColors.fat)
                                        .frame(width: barWidth, height: max(barHeight * entry.fatPercent, 0))

                                    // Carbs (middle)
                                    Rectangle()
                                        .fill(FuelColors.carbs)
                                        .frame(width: barWidth, height: max(barHeight * entry.carbsPercent, 0))

                                    // Protein (bottom)
                                    Rectangle()
                                        .fill(FuelColors.protein)
                                        .frame(width: barWidth, height: max(barHeight * entry.proteinPercent, 0))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            } else if entry.calories > 0 {
                                // No macro breakdown — single bar
                                Rectangle()
                                    .fill(FuelColors.primary)
                                    .frame(width: barWidth, height: max(barHeight, 0))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }

                            Text(entry.dayOfWeek)
                                .font(.system(size: 9))
                                .foregroundStyle(FuelColors.textTertiary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - X-Axis Helpers

    @available(iOS 16.0, *)
    private var xAxisValues: AxisMarkValues {
        switch timeRange {
        case .week:
            return .stride(by: .day)
        case .month:
            return .stride(by: .day, count: 5)
        case .threeMonths:
            return .stride(by: .weekOfYear, count: 2)
        case .year:
            return .stride(by: .month)
        }
    }

    private func xAxisLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        switch timeRange {
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "MMM d"
        case .threeMonths:
            formatter.dateFormat = "MMM d"
        case .year:
            formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
    }

    // MARK: - Tooltip

    private func tooltipView(for entry: CalorieDataPoint) -> some View {
        VStack(spacing: FuelSpacing.sm) {
            // Header with date and total calories
            HStack(spacing: FuelSpacing.sm) {
                Circle()
                    .fill(entry.isUnderGoal ? FuelColors.success : FuelColors.error)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.formattedDate)
                        .font(.system(size: 10))
                        .foregroundStyle(FuelColors.textTertiary)

                    HStack(spacing: 4) {
                        Text("\(entry.calories)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(FuelColors.textPrimary)

                        Text("cal")
                            .font(.system(size: 12))
                            .foregroundStyle(FuelColors.textSecondary)
                    }
                }

                Spacer()

                // Difference from goal
                let diff = entry.calories - goal
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: diff > 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(entry.isUnderGoal ? FuelColors.success : FuelColors.error)

                    Text("\(abs(diff))")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(entry.isUnderGoal ? FuelColors.success : FuelColors.error)
                }
            }

            // Macro breakdown
            HStack(spacing: FuelSpacing.md) {
                macroItem(
                    label: "P",
                    value: Int(entry.proteinPercent * 100),
                    color: FuelColors.protein
                )
                macroItem(
                    label: "C",
                    value: Int(entry.carbsPercent * 100),
                    color: FuelColors.carbs
                )
                macroItem(
                    label: "F",
                    value: Int(entry.fatPercent * 100),
                    color: FuelColors.fat
                )
            }
        }
        .padding(.horizontal, FuelSpacing.md)
        .padding(.vertical, FuelSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: FuelSpacing.radiusMd)
                .fill(FuelColors.surface)
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        )
        .padding(.top, FuelSpacing.xs)
    }

    private func macroItem(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(FuelColors.textTertiary)

            Text("\(value)%")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Macro Legend

struct MacroLegend: View {
    var body: some View {
        HStack(spacing: FuelSpacing.lg) {
            legendItem(label: "Protein", color: FuelColors.protein)
            legendItem(label: "Carbs", color: FuelColors.carbs)
            legendItem(label: "Fat", color: FuelColors.fat)
        }
    }

    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    CalorieChartView(
        entries: [
            CalorieDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), calories: 1850, goal: 2000, protein: 120, carbs: 200, fat: 60),
            CalorieDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), calories: 2100, goal: 2000, protein: 140, carbs: 230, fat: 70),
            CalorieDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), calories: 1950, goal: 2000, protein: 130, carbs: 210, fat: 65),
            CalorieDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), calories: 1780, goal: 2000, protein: 110, carbs: 190, fat: 55),
            CalorieDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), calories: 2200, goal: 2000, protein: 150, carbs: 250, fat: 75),
            CalorieDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), calories: 1900, goal: 2000, protein: 125, carbs: 205, fat: 62),
            CalorieDataPoint(date: Date(), calories: 1650, goal: 2000, protein: 100, carbs: 175, fat: 50)
        ],
        goal: 2000
    )
    .frame(height: 180)
    .padding()
    .background(FuelColors.surface)
}

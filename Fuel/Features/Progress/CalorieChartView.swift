import SwiftUI
import Charts

/// Calorie Chart View
/// Interactive bar chart showing daily calorie intake with animations

struct CalorieChartView: View {
    let entries: [CalorieDataPoint]
    let goal: Int

    @State private var selectedEntry: CalorieDataPoint?
    @State private var lastSelectedId: UUID?
    @State private var animatedEntries: Set<UUID> = []
    @State private var hasAppeared = false

    private var maxCalories: Int {
        max(entries.map { $0.calories }.max() ?? 0, goal) + 200
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            swiftChartsView
                .onAppear {
                    if !hasAppeared {
                        hasAppeared = true
                        animateBarsIn()
                    }
                }
        } else {
            customChartView
        }
    }

    // MARK: - Bar Animation

    private func animateBarsIn() {
        for (index, entry) in entries.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    _ = animatedEntries.insert(entry.id)
                }
            }
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

            // Calorie bars with animation
            ForEach(entries) { entry in
                let isSelected = selectedEntry?.id == entry.id
                let isAnimated = animatedEntries.contains(entry.id)

                BarMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Calories", isAnimated ? entry.calories : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: entry.isUnderGoal
                            ? [FuelColors.success, FuelColors.success.opacity(0.7)]
                            : [FuelColors.error, FuelColors.error.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(6)
                .opacity(isSelected ? 1.0 : 0.85)
                .annotation(position: .top) {
                    if isSelected {
                        Text("\(entry.calories)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(entry.isUnderGoal ? FuelColors.success : FuelColors.error)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .chartYScale(domain: 0...maxCalories)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    let isSelected = selectedEntry.map { Calendar.current.isDate($0.date, inSameDayAs: date) } ?? false
                    AxisValueLabel {
                        Text(dayOfWeek(from: date))
                            .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                            .foregroundStyle(isSelected ? FuelColors.primary : FuelColors.textTertiary)
                    }
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

                // Bars
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(entries) { entry in
                        let barHeight = height * CGFloat(entry.calories) / CGFloat(maxCalories)

                        VStack(spacing: FuelSpacing.xxxs) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(entry.isUnderGoal ? FuelColors.success : FuelColors.error)
                                .frame(width: barWidth, height: max(barHeight, 4))

                            Text(entry.dayOfWeek)
                                .font(.system(size: 9))
                                .foregroundStyle(FuelColors.textTertiary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    // MARK: - Tooltip

    private func tooltipView(for entry: CalorieDataPoint) -> some View {
        HStack(spacing: FuelSpacing.sm) {
            // Status indicator
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
        .padding(.horizontal, FuelSpacing.md)
        .padding(.vertical, FuelSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: FuelSpacing.radiusMd)
                .fill(FuelColors.surface)
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        )
        .padding(.top, FuelSpacing.xs)
    }
}

// MARK: - Preview

#Preview {
    CalorieChartView(
        entries: [
            CalorieDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), calories: 1850, goal: 2000),
            CalorieDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), calories: 2100, goal: 2000),
            CalorieDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), calories: 1950, goal: 2000),
            CalorieDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), calories: 1780, goal: 2000),
            CalorieDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), calories: 2200, goal: 2000),
            CalorieDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), calories: 1900, goal: 2000),
            CalorieDataPoint(date: Date(), calories: 1650, goal: 2000)
        ],
        goal: 2000
    )
    .frame(height: 180)
    .padding()
    .background(FuelColors.surface)
}

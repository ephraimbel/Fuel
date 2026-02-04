import SwiftUI
import Charts

/// Calorie Chart View
/// Bar chart showing daily calorie intake

struct CalorieChartView: View {
    let entries: [CalorieDataPoint]
    let goal: Int

    @State private var selectedEntry: CalorieDataPoint?

    private var maxCalories: Int {
        max(entries.map { $0.calories }.max() ?? 0, goal) + 200
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            swiftChartsView
        } else {
            customChartView
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

            // Calorie bars
            ForEach(entries) { entry in
                BarMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Calories", entry.calories)
                )
                .foregroundStyle(entry.isUnderGoal ? FuelColors.success : FuelColors.error)
                .cornerRadius(4)
                .opacity(selectedEntry?.id == entry.id ? 1.0 : 0.8)
            }
        }
        .chartYScale(domain: 0...maxCalories)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(dayOfWeek(from: date))
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)
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
                                    selectedEntry = entries.min(by: {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    })
                                    FuelHaptics.shared.tap()
                                }
                            }
                            .onEnded { _ in
                                selectedEntry = nil
                            }
                    )
            }
        }
        .overlay {
            if let entry = selectedEntry {
                tooltipView(for: entry)
            }
        }
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
        VStack(spacing: FuelSpacing.xxxs) {
            Text(entry.formattedDate)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            Text("\(entry.calories) cal")
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(entry.isUnderGoal ? FuelColors.success : FuelColors.error)

            Text(entry.isUnderGoal ? "Under goal" : "Over goal")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
        }
        .padding(FuelSpacing.sm)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, FuelSpacing.sm)
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

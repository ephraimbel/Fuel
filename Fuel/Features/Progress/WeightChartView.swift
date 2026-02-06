import SwiftUI
import Charts

/// Weight Chart View
/// Interactive line chart showing weight progress with animations

struct WeightChartView: View {
    let entries: [WeightDataPoint]
    let goalWeight: Double
    var timeRange: TimeRange = .week

    @State private var selectedEntry: WeightDataPoint?
    @State private var lastSelectedId: UUID?
    @State private var lineProgress: CGFloat = 0
    @State private var hasAppeared = false

    private var minWeight: Double {
        guard !entries.isEmpty else { return goalWeight - 10 }
        let minEntry = entries.map { $0.weight }.min() ?? goalWeight
        return min(minEntry, goalWeight) - 5
    }

    private var maxWeight: Double {
        guard !entries.isEmpty else { return goalWeight + 10 }
        let maxEntry = entries.map { $0.weight }.max() ?? goalWeight
        return max(maxEntry, goalWeight) + 5
    }

    /// Minimum width so data points stay readable
    private var chartWidth: CGFloat? {
        let count = CGFloat(entries.count)
        guard count > 10 else { return nil }
        switch timeRange {
        case .week:
            return nil
        case .month:
            return max(count * 20, 500)
        case .threeMonths:
            return max(count * 14, 900)
        case .year:
            return max(count * 8, 2000)
        }
    }

    private var needsScroll: Bool { chartWidth != nil }

    var body: some View {
        VStack(spacing: FuelSpacing.sm) {
            // Chart
            chartContent
                .frame(maxWidth: .infinity)
                .onAppear {
                    if !hasAppeared && !entries.isEmpty {
                        hasAppeared = true
                        withAnimation(.easeOut(duration: 1.2)) {
                            lineProgress = 1.0
                        }
                    }
                }
                .onChange(of: entries.count) { _, newCount in
                    if newCount > 0 && !hasAppeared {
                        hasAppeared = true
                        withAnimation(.easeOut(duration: 1.2)) {
                            lineProgress = 1.0
                        }
                    }
                }

            // Legend
            legendView
        }
    }

    // MARK: - Chart Content

    @ViewBuilder
    private var chartContent: some View {
        if entries.isEmpty {
            emptyChartView
        } else if #available(iOS 16.0, *) {
            if needsScroll {
                ScrollView(.horizontal, showsIndicators: false) {
                    swiftChartsView
                        .frame(width: chartWidth)
                }
            } else {
                swiftChartsView
            }
        } else {
            customChartView
        }
    }

    // MARK: - Empty State

    private var emptyChartView: some View {
        VStack(spacing: FuelSpacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundStyle(FuelColors.textTertiary)

            Text("No weight data yet")
                .font(FuelTypography.subheadline)
                .foregroundStyle(FuelColors.textTertiary)

            Text("Log your weight to see trends")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FuelColors.surfaceSecondary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
    }

    // MARK: - Swift Charts (iOS 16+)

    @available(iOS 16.0, *)
    private var swiftChartsView: some View {
        Chart {
            // Goal line
            RuleMark(y: .value("Goal", goalWeight))
                .foregroundStyle(FuelColors.success.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))

            // Weight data
            ForEach(entries) { entry in
                // Area under the line
                AreaMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            FuelColors.primary.opacity(0.25),
                            FuelColors.primary.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                // Line
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(FuelColors.primary)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)

                // Points
                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(selectedEntry?.id == entry.id ? FuelColors.primary : .white)
                .symbolSize(selectedEntry?.id == entry.id ? 80 : 40)
            }

            // Point borders
            ForEach(entries) { entry in
                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(FuelColors.primary)
                .symbolSize(selectedEntry?.id == entry.id ? 120 : 60)
                .symbol {
                    Circle()
                        .strokeBorder(FuelColors.primary, lineWidth: 2)
                        .background(Circle().fill(selectedEntry?.id == entry.id ? FuelColors.primary : .white))
                        .frame(width: selectedEntry?.id == entry.id ? 10 : 8)
                }
            }
        }
        .chartYScale(domain: minWeight...maxWeight)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                    .foregroundStyle(FuelColors.surfaceSecondary)
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                    .foregroundStyle(FuelColors.surfaceSecondary)
                AxisValueLabel {
                    if let weight = value.as(Double.self) {
                        Text("\(Int(weight))")
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                }
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(FuelColors.surfaceSecondary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
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
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                            selectedEntry = closest
                                        }
                                        // Haptic feedback - tick for each point
                                        FuelHaptics.shared.select()
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedEntry = nil
                                }
                                lastSelectedId = nil
                                // Light haptic on release
                                FuelHaptics.shared.tap()
                            }
                    )
            }
        }
        .overlay(alignment: .topLeading) {
            if let entry = selectedEntry {
                tooltipView(for: entry)
                    .padding(FuelSpacing.sm)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selectedEntry?.id)
    }

    // MARK: - Custom Chart (Fallback for iOS 15)

    private var customChartView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let range = maxWeight - minWeight
            let padding: CGFloat = 8

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: FuelSpacing.radiusSm)
                    .fill(FuelColors.surfaceSecondary.opacity(0.2))

                // Grid lines
                ForEach(0..<5, id: \.self) { i in
                    let y = padding + (height - padding * 2) * CGFloat(i) / 4
                    Path { path in
                        path.move(to: CGPoint(x: padding, y: y))
                        path.addLine(to: CGPoint(x: width - padding, y: y))
                    }
                    .stroke(FuelColors.surfaceSecondary, lineWidth: 1)
                }

                // Goal line
                let goalY = padding + (height - padding * 2) * (1 - CGFloat((goalWeight - minWeight) / range))
                Path { path in
                    path.move(to: CGPoint(x: padding, y: goalY))
                    path.addLine(to: CGPoint(x: width - padding, y: goalY))
                }
                .stroke(FuelColors.success.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))

                // Weight line and area
                if entries.count > 1 {
                    // Area fill
                    Path { path in
                        for (index, entry) in entries.enumerated() {
                            let x = padding + (width - padding * 2) * CGFloat(index) / CGFloat(entries.count - 1)
                            let y = padding + (height - padding * 2) * (1 - CGFloat((entry.weight - minWeight) / range))

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: height - padding))
                                path.addLine(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        let lastX = padding + (width - padding * 2)
                        path.addLine(to: CGPoint(x: lastX, y: height - padding))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [FuelColors.primary.opacity(0.25), FuelColors.primary.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line
                    Path { path in
                        for (index, entry) in entries.enumerated() {
                            let x = padding + (width - padding * 2) * CGFloat(index) / CGFloat(entries.count - 1)
                            let y = padding + (height - padding * 2) * (1 - CGFloat((entry.weight - minWeight) / range))

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(FuelColors.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    // Points
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        let x = padding + (width - padding * 2) * CGFloat(index) / CGFloat(entries.count - 1)
                        let y = padding + (height - padding * 2) * (1 - CGFloat((entry.weight - minWeight) / range))

                        Circle()
                            .fill(.white)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .strokeBorder(FuelColors.primary, lineWidth: 2)
                            )
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }

    // MARK: - Legend

    private var legendView: some View {
        HStack(spacing: FuelSpacing.lg) {
            legendItem(color: FuelColors.primary, label: "Weight")
            legendItem(color: FuelColors.success, label: "Goal", isDashed: true)
        }
    }

    private func legendItem(color: Color, label: String, isDashed: Bool = false) -> some View {
        HStack(spacing: FuelSpacing.xs) {
            if isDashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(color)
                            .frame(width: 4, height: 2)
                    }
                }
                .frame(width: 16)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 3)
                    .clipShape(Capsule())
            }

            Text(label)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)
        }
    }

    // MARK: - Tooltip

    private func tooltipView(for entry: WeightDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.formattedDate)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            Text(String(format: "%.1f lbs", entry.weight))
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(FuelColors.textPrimary)
        }
        .padding(.horizontal, FuelSpacing.sm)
        .padding(.vertical, FuelSpacing.xs)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusSm))
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // With data
        WeightChartView(
            entries: [
                WeightDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), weight: 170),
                WeightDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), weight: 169),
                WeightDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), weight: 168.5),
                WeightDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), weight: 167),
                WeightDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), weight: 166.5),
                WeightDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), weight: 166),
                WeightDataPoint(date: Date(), weight: 165)
            ],
            goalWeight: 160
        )
        .frame(height: 180)

        // Empty state
        WeightChartView(
            entries: [],
            goalWeight: 160
        )
        .frame(height: 180)
    }
    .padding()
    .background(FuelColors.surface)
}

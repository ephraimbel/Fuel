import SwiftUI
import Charts

/// Weight Chart View
/// Line chart showing weight progress over time

struct WeightChartView: View {
    let entries: [WeightDataPoint]
    let goalWeight: Double

    @State private var selectedEntry: WeightDataPoint?

    private var minWeight: Double {
        let minEntry = entries.map { $0.weight }.min() ?? 0
        return min(minEntry, goalWeight) - 5
    }

    private var maxWeight: Double {
        let maxEntry = entries.map { $0.weight }.max() ?? 0
        return max(maxEntry, goalWeight) + 5
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
            RuleMark(y: .value("Goal", goalWeight))
                .foregroundStyle(FuelColors.primary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .trailing, alignment: .leading) {
                    Text("Goal")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.primary)
                }

            // Weight line
            ForEach(entries) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(FuelColors.primary)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [FuelColors.primary.opacity(0.3), FuelColors.primary.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(FuelColors.primary)
                .symbolSize(selectedEntry?.id == entry.id ? 100 : 30)
            }
        }
        .chartYScale(domain: minWeight...maxWeight)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisValueLabel(format: .dateTime.month().day())
                    .foregroundStyle(FuelColors.textTertiary)
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
            let range = maxWeight - minWeight

            ZStack {
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
                let goalY = height * (1 - CGFloat((goalWeight - minWeight) / range))
                Path { path in
                    path.move(to: CGPoint(x: 0, y: goalY))
                    path.addLine(to: CGPoint(x: width, y: goalY))
                }
                .stroke(FuelColors.primary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))

                // Weight line
                if entries.count > 1 {
                    Path { path in
                        for (index, entry) in entries.enumerated() {
                            let x = width * CGFloat(index) / CGFloat(entries.count - 1)
                            let y = height * (1 - CGFloat((entry.weight - minWeight) / range))

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(FuelColors.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    // Points
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        let x = width * CGFloat(index) / CGFloat(entries.count - 1)
                        let y = height * (1 - CGFloat((entry.weight - minWeight) / range))

                        Circle()
                            .fill(FuelColors.primary)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }

    // MARK: - Tooltip

    private func tooltipView(for entry: WeightDataPoint) -> some View {
        VStack(spacing: FuelSpacing.xxxs) {
            Text(entry.formattedDate)
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            Text(String(format: "%.1f lbs", entry.weight))
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(FuelColors.textPrimary)
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
        goalWeight: 155
    )
    .frame(height: 200)
    .padding()
    .background(FuelColors.surface)
}

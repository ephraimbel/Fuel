import SwiftUI

/// Animated Number View
/// Counts up from 0 to target value with easing animation

struct AnimatedNumber: View {
    let value: Double
    let format: String
    let duration: Double
    let onComplete: (() -> Void)?

    @State private var displayValue: Double = 0
    @State private var hasAnimated = false

    init(
        value: Double,
        format: String = "%.0f",
        duration: Double = 0.8,
        onComplete: (() -> Void)? = nil
    ) {
        self.value = value
        self.format = format
        self.duration = duration
        self.onComplete = onComplete
    }

    var body: some View {
        Text(String(format: format, displayValue))
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                animateValue()
            }
            .onChange(of: value) { _, newValue in
                animateValue(to: newValue)
            }
    }

    private func animateValue(to target: Double? = nil) {
        let targetValue = target ?? value
        let startValue = displayValue
        let change = targetValue - startValue

        guard change != 0 else { return }

        let startTime = Date()
        let timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)

            // Ease out cubic
            let easedProgress = 1 - pow(1 - progress, 3)

            displayValue = startValue + (change * easedProgress)

            if progress >= 1.0 {
                timer.invalidate()
                displayValue = targetValue
                onComplete?()
            }
        }
        RunLoop.current.add(timer, forMode: .common)
    }
}

/// Animated Integer View
/// Specialized for whole numbers with optional suffix

struct AnimatedInteger: View {
    let value: Int
    let suffix: String
    let duration: Double
    let font: Font
    let color: Color
    let onComplete: (() -> Void)?

    @State private var displayValue: Double = 0
    @State private var hasAnimated = false

    init(
        value: Int,
        suffix: String = "",
        duration: Double = 0.8,
        font: Font = .body,
        color: Color = FuelColors.textPrimary,
        onComplete: (() -> Void)? = nil
    ) {
        self.value = value
        self.suffix = suffix
        self.duration = duration
        self.font = font
        self.color = color
        self.onComplete = onComplete
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(Int(displayValue))")
                .font(font)
                .foregroundStyle(color)
                .contentTransition(.numericText(value: displayValue))

            if !suffix.isEmpty {
                Text(suffix)
                    .font(font)
                    .foregroundStyle(color.opacity(0.7))
            }
        }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            animateValue()
        }
        .onChange(of: value) { _, newValue in
            animateValue(to: Double(newValue))
        }
    }

    private func animateValue(to target: Double? = nil) {
        let targetValue = target ?? Double(value)
        let startValue = displayValue
        let change = targetValue - startValue

        guard change != 0 else { return }

        let startTime = Date()
        let timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)

            // Ease out cubic
            let easedProgress = 1 - pow(1 - progress, 3)

            displayValue = startValue + (change * easedProgress)

            if progress >= 1.0 {
                timer.invalidate()
                displayValue = targetValue
                onComplete?()
            }
        }
        RunLoop.current.add(timer, forMode: .common)
    }
}

/// Animated Percentage View
/// Shows percentage with animated ring sync option

struct AnimatedPercentage: View {
    let value: Double // 0.0 to 1.0
    let duration: Double
    let font: Font
    let color: Color

    @State private var displayValue: Double = 0
    @State private var hasAnimated = false

    init(
        value: Double,
        duration: Double = 1.0,
        font: Font = .body,
        color: Color = FuelColors.textPrimary
    ) {
        self.value = value
        self.duration = duration
        self.font = font
        self.color = color
    }

    var body: some View {
        Text("\(Int(displayValue * 100))%")
            .font(font)
            .foregroundStyle(color)
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                animateValue()
            }
            .onChange(of: value) { _, newValue in
                animateValue(to: newValue)
            }
    }

    private func animateValue(to target: Double? = nil) {
        let targetValue = target ?? value
        let startValue = displayValue
        let change = targetValue - startValue

        guard change != 0 else { return }

        let startTime = Date()
        let timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)

            // Ease out cubic - matches ring animation
            let easedProgress = 1 - pow(1 - progress, 3)

            displayValue = startValue + (change * easedProgress)

            if progress >= 1.0 {
                timer.invalidate()
                displayValue = targetValue
            }
        }
        RunLoop.current.add(timer, forMode: .common)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        AnimatedInteger(
            value: 1847,
            suffix: "cal",
            font: .system(size: 32, weight: .bold, design: .rounded)
        )

        AnimatedPercentage(
            value: 0.85,
            font: .system(size: 24, weight: .semibold, design: .rounded)
        )

        AnimatedNumber(value: 165.5, format: "%.1f")
    }
    .padding()
}

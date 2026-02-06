import SwiftUI

/// Calculating Screen
/// Shows animated progress while calculating the user's personalized plan

struct CalculatingScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var currentStep = 0
    @State private var progress: Double = 0
    @State private var flameScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.4
    @State private var rotationAngle: Double = 0
    @State private var embers: [Ember] = []

    private let steps = [
        "Analyzing your profile...",
        "Calculating metabolism...",
        "Setting macro targets...",
        "Personalizing your plan..."
    ]

    var body: some View {
        VStack(spacing: FuelSpacing.xxl) {
            Spacer()

            // Animated fire icon
            ZStack {
                // Outer glow rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.orange.opacity(0.3 - Double(index) * 0.1),
                                    Color.orange.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: CGFloat(60 + index * 25)
                            )
                        )
                        .frame(width: CGFloat(120 + index * 50), height: CGFloat(120 + index * 50))
                        .scaleEffect(1 + sin(progress * .pi * 2 + Double(index) * 0.5) * 0.08)
                }

                // Pulsing glow behind fire
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.orange.opacity(glowOpacity),
                                Color.red.opacity(glowOpacity * 0.5),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)

                // Rising embers
                ForEach(embers) { ember in
                    Circle()
                        .fill(ember.color)
                        .frame(width: ember.size, height: ember.size)
                        .offset(x: ember.x, y: ember.y)
                        .opacity(ember.opacity)
                        .blur(radius: ember.size > 4 ? 1 : 0)
                }

                // Orbiting particles
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(
                            index % 2 == 0
                                ? Color.orange.opacity(0.8)
                                : Color.yellow.opacity(0.6)
                        )
                        .frame(width: index % 2 == 0 ? 6 : 4, height: index % 2 == 0 ? 6 : 4)
                        .offset(y: -55)
                        .rotationEffect(.degrees(rotationAngle + Double(index) * 60))
                        .opacity(0.7 + sin(progress * .pi * 4 + Double(index)) * 0.3)
                }

                // Main fire icon with gradient
                ZStack {
                    // Shadow/glow layer
                    Image(systemName: "flame.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blur(radius: 8)
                        .opacity(0.6)

                    // Main flame
                    Image(systemName: "flame.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.85, blue: 0.2),  // Bright yellow
                                    Color.orange,
                                    Color(red: 1.0, green: 0.3, blue: 0.1)   // Deep orange-red
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .scaleEffect(flameScale)
                .offset(y: sin(progress * .pi * 6) * 2) // Subtle float
            }
            .frame(height: 220)

            // Progress text
            VStack(spacing: FuelSpacing.md) {
                Text("Creating Your Plan")
                    .font(FuelTypography.title2)
                    .foregroundStyle(FuelColors.textPrimary)

                Text(steps[min(currentStep, steps.count - 1)])
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textSecondary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }

            // Progress bar with gradient
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FuelColors.surfaceSecondary)
                        .frame(height: 8)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.6, blue: 0.0),
                                    Color.orange,
                                    Color(red: 1.0, green: 0.3, blue: 0.1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * progress), height: 8)
                        .shadow(color: .orange.opacity(0.5), radius: 4, x: 0, y: 0)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, FuelSpacing.xxl)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, FuelSpacing.screenHorizontal)
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Total duration for the calculating animation
        let totalDuration = 2.0
        let stepDuration = totalDuration / Double(steps.count)

        // Progress bar animation
        withAnimation(.easeInOut(duration: totalDuration)) {
            progress = 1.0
        }

        // Flame pulse animation (continuous)
        withAnimation(
            .easeInOut(duration: 0.6)
            .repeatForever(autoreverses: true)
        ) {
            flameScale = 1.08
        }

        // Glow pulse animation
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 0.7
        }

        // Orbiting particles rotation
        withAnimation(
            .linear(duration: 3)
            .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }

        // Step text animation with haptics
        for i in 0..<steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = i
                }
                FuelHaptics.shared.tick()
            }
        }

        // Start ember generation
        startEmberAnimation()
    }

    private func startEmberAnimation() {
        // Generate embers continuously
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            // Stop after animation completes
            if progress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    timer.invalidate()
                }
            }

            // Create new ember
            let ember = Ember(
                x: CGFloat.random(in: -30...30),
                y: 20,
                size: CGFloat.random(in: 3...7),
                color: [Color.orange, Color.yellow, Color(red: 1, green: 0.5, blue: 0.2)].randomElement()!,
                opacity: Double.random(in: 0.6...1.0)
            )
            embers.append(ember)

            // Animate ember rising
            if let index = embers.firstIndex(where: { $0.id == ember.id }) {
                withAnimation(.easeOut(duration: Double.random(in: 1.0...1.5))) {
                    embers[index].y = CGFloat.random(in: -100 ... -60)
                    embers[index].x += CGFloat.random(in: -20...20)
                    embers[index].opacity = 0
                }
            }

            // Clean up old embers
            embers.removeAll { $0.opacity <= 0.1 }

            // Limit ember count
            if embers.count > 15 {
                embers.removeFirst()
            }
        }
    }
}

// MARK: - Ember Model

private struct Ember: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
}

#Preview {
    CalculatingScreen(viewModel: OnboardingViewModel())
        .background(FuelColors.background)
}

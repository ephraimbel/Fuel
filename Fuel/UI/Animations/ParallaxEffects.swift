import SwiftUI

/// Parallax Scroll Effects
/// Premium scroll interactions with depth and motion

// MARK: - Parallax Scroll View

struct ParallaxScrollView<Content: View>: View {
    let content: Content
    let onScrollChange: ((CGFloat) -> Void)?

    @State private var scrollOffset: CGFloat = 0

    init(
        onScrollChange: ((CGFloat) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.onScrollChange = onScrollChange
        self.content = content()
    }

    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .global).minY
                    )
            }
            .frame(height: 0)

            content
        }
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            scrollOffset = offset
            onScrollChange?(offset)
        }
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Parallax Header

struct ParallaxHeader<Content: View>: View {
    let height: CGFloat
    let content: Content

    @State private var offset: CGFloat = 0

    init(height: CGFloat = 200, @ViewBuilder content: () -> Content) {
        self.height = height
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            let minY = geometry.frame(in: .global).minY
            let parallaxOffset = minY > 0 ? -minY * 0.5 : 0

            content
                .frame(width: geometry.size.width, height: height + (minY > 0 ? minY : 0))
                .offset(y: parallaxOffset)
                .clipped()
        }
        .frame(height: height)
    }
}

// MARK: - Depth Card Modifier

struct DepthCardModifier: ViewModifier {
    let scrollOffset: CGFloat
    let cardOffset: CGFloat
    let maxShadow: CGFloat
    let maxLift: CGFloat

    init(
        scrollOffset: CGFloat,
        cardOffset: CGFloat,
        maxShadow: CGFloat = 20,
        maxLift: CGFloat = 4
    ) {
        self.scrollOffset = scrollOffset
        self.cardOffset = cardOffset
        self.maxShadow = maxShadow
        self.maxLift = maxLift
    }

    private var shadowIntensity: CGFloat {
        let distance = abs(scrollOffset - cardOffset)
        let normalized = 1 - min(distance / 500, 1)
        return normalized
    }

    func body(content: Content) -> some View {
        content
            .shadow(
                color: .black.opacity(0.04 + (0.08 * shadowIntensity)),
                radius: 8 + (maxShadow * shadowIntensity),
                x: 0,
                y: 2 + (maxLift * shadowIntensity)
            )
    }
}

// MARK: - Sticky Header

struct StickyHeader<Content: View>: View {
    let minHeight: CGFloat
    let maxHeight: CGFloat
    @ViewBuilder let content: () -> Content

    @State private var headerHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let minY = geometry.frame(in: .global).minY
            let safeAreaTop = geometry.safeAreaInsets.top
            let isSticky = minY <= safeAreaTop

            VStack(spacing: 0) {
                content()
            }
            .frame(height: isSticky ? minHeight : maxHeight)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSticky {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .blur(radius: 0.5)
                    } else {
                        FuelColors.background
                    }
                }
            )
            .offset(y: isSticky ? -minY + safeAreaTop : 0)
            .animation(.easeOut(duration: 0.15), value: isSticky)
        }
        .frame(height: maxHeight)
    }
}

// MARK: - Scroll Fade Modifier

struct ScrollFadeModifier: ViewModifier {
    let scrollOffset: CGFloat
    let fadeStart: CGFloat
    let fadeEnd: CGFloat

    private var opacity: Double {
        if scrollOffset >= fadeEnd {
            return 0
        } else if scrollOffset <= fadeStart {
            return 1
        } else {
            return Double(1 - (scrollOffset - fadeStart) / (fadeEnd - fadeStart))
        }
    }

    func body(content: Content) -> some View {
        content.opacity(opacity)
    }
}

// MARK: - Scroll Scale Modifier

struct ScrollScaleModifier: ViewModifier {
    let scrollOffset: CGFloat
    let scaleStart: CGFloat
    let minScale: CGFloat

    private var scale: CGFloat {
        if scrollOffset <= 0 {
            return 1.0
        } else {
            let normalized = min(scrollOffset / scaleStart, 1.0)
            return 1.0 - (normalized * (1.0 - minScale))
        }
    }

    func body(content: Content) -> some View {
        content.scaleEffect(scale)
    }
}

// MARK: - View Extensions

extension View {
    /// Add depth shadow that intensifies based on scroll position
    func depthCard(scrollOffset: CGFloat, cardOffset: CGFloat) -> some View {
        modifier(DepthCardModifier(scrollOffset: scrollOffset, cardOffset: cardOffset))
    }

    /// Fade out content as user scrolls
    func scrollFade(offset: CGFloat, fadeStart: CGFloat = 50, fadeEnd: CGFloat = 150) -> some View {
        modifier(ScrollFadeModifier(scrollOffset: offset, fadeStart: fadeStart, fadeEnd: fadeEnd))
    }

    /// Scale down content as user scrolls
    func scrollScale(offset: CGFloat, scaleStart: CGFloat = 100, minScale: CGFloat = 0.9) -> some View {
        modifier(ScrollScaleModifier(scrollOffset: offset, scaleStart: scaleStart, minScale: minScale))
    }
}

// MARK: - Floating Card Effect

struct FloatingCardEffect: ViewModifier {
    @State private var isFloating = false

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -2 : 2)
            .animation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isFloating = true
            }
    }
}

extension View {
    /// Add subtle floating animation
    func floatingEffect() -> some View {
        modifier(FloatingCardEffect())
    }
}

// MARK: - Preview

#Preview {
    ParallaxScrollView { offset in
        print("Scroll: \(offset)")
    } content: {
        VStack(spacing: 20) {
            ForEach(0..<10, id: \.self) { i in
                RoundedRectangle(cornerRadius: 16)
                    .fill(FuelColors.surface)
                    .frame(height: 120)
                    .overlay(Text("Card \(i + 1)"))
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    .background(FuelColors.background)
}

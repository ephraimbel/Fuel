import SwiftUI

/// Help Center View
/// FAQs and support information

struct HelpCenterView: View {
    @State private var searchText = ""
    @State private var expandedFAQ: String? = nil

    private let faqs: [FAQItem] = [
        FAQItem(
            question: "How does AI food scanning work?",
            answer: "Point your camera at any meal and tap the capture button. Our AI analyzes the image to identify foods and estimate their nutritional content. The more clearly the food is visible, the more accurate the results.",
            category: "Scanning"
        ),
        FAQItem(
            question: "How accurate is the calorie estimation?",
            answer: "Our AI provides estimates that are typically within 10-20% of actual values. For the most accurate tracking, we recommend verifying and adjusting portions when needed, especially for homemade meals.",
            category: "Scanning"
        ),
        FAQItem(
            question: "Can I scan barcodes?",
            answer: "Yes! Tap the barcode icon to scan product barcodes. We use the Open Food Facts database with millions of products. If a product isn't found, you can add it manually.",
            category: "Scanning"
        ),
        FAQItem(
            question: "How are my calorie goals calculated?",
            answer: "We use the Mifflin-St Jeor equation, which considers your age, gender, height, weight, and activity level to calculate your basal metabolic rate (BMR). Your goal is then adjusted based on whether you want to lose, maintain, or gain weight.",
            category: "Goals"
        ),
        FAQItem(
            question: "What do the macro percentages mean?",
            answer: "Macros (protein, carbs, fat) are the main nutrients that provide calories. A typical balanced diet is around 30% protein, 40% carbs, and 30% fat, but this can be adjusted based on your goals.",
            category: "Goals"
        ),
        FAQItem(
            question: "How do I maintain my streak?",
            answer: "Log at least one meal every day to maintain your streak. You'll receive a reminder notification if you haven't logged anything by evening.",
            category: "Tracking"
        ),
        FAQItem(
            question: "Can I edit or delete logged meals?",
            answer: "Yes! Tap on any logged meal to edit the foods, portions, or delete items. Swipe left on a meal to delete it entirely.",
            category: "Tracking"
        ),
        FAQItem(
            question: "Is my data synced across devices?",
            answer: "Premium members get iCloud sync, which keeps your data in sync across all your Apple devices automatically.",
            category: "Account"
        ),
        FAQItem(
            question: "How do I cancel my subscription?",
            answer: "Go to Settings > Subscription > Manage in App Store. From there, you can modify or cancel your subscription. You'll continue to have access until the end of your billing period.",
            category: "Account"
        )
    ]

    var filteredFAQs: [FAQItem] {
        if searchText.isEmpty {
            return faqs
        }
        return faqs.filter {
            $0.question.localizedCaseInsensitiveContains(searchText) ||
            $0.answer.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: FuelSpacing.xl) {
                // Search
                searchBar

                // Quick help
                quickHelpSection

                // FAQs
                faqSection

                // Contact
                contactSection
            }
            .padding(.horizontal, FuelSpacing.screenHorizontal)
            .padding(.vertical, FuelSpacing.lg)
        }
        .background(FuelColors.background)
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: FuelSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FuelColors.textTertiary)

            TextField("Search help articles...", text: $searchText)
                .font(FuelTypography.body)
                .foregroundStyle(FuelColors.textPrimary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(FuelColors.textTertiary)
                }
            }
        }
        .padding(FuelSpacing.sm)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Quick Help Section

    private var quickHelpSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("QUICK HELP")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            HStack(spacing: FuelSpacing.sm) {
                quickHelpCard(
                    icon: "camera.fill",
                    title: "Scanning",
                    color: FuelColors.primary
                )

                quickHelpCard(
                    icon: "target",
                    title: "Goals",
                    color: .blue
                )

                quickHelpCard(
                    icon: "chart.bar.fill",
                    title: "Progress",
                    color: .purple
                )
            }
        }
    }

    private func quickHelpCard(icon: String, title: String, color: Color) -> some View {
        Button {
            FuelHaptics.shared.tap()
        } label: {
            VStack(spacing: FuelSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)

                Text(title)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(FuelSpacing.md)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    // MARK: - FAQ Section

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("FREQUENTLY ASKED QUESTIONS")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: FuelSpacing.sm) {
                ForEach(filteredFAQs, id: \.question) { faq in
                    faqRow(faq)
                }
            }
        }
    }

    private func faqRow(_ faq: FAQItem) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(FuelAnimations.spring) {
                    if expandedFAQ == faq.question {
                        expandedFAQ = nil
                    } else {
                        expandedFAQ = faq.question
                    }
                }
                FuelHaptics.shared.tap()
            } label: {
                HStack(spacing: FuelSpacing.md) {
                    VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                        Text(faq.category)
                            .font(FuelTypography.caption)
                            .foregroundStyle(FuelColors.primary)

                        Text(faq.question)
                            .font(FuelTypography.subheadlineMedium)
                            .foregroundStyle(FuelColors.textPrimary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: expandedFAQ == faq.question ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(FuelColors.textTertiary)
                }
                .padding(FuelSpacing.md)
            }

            if expandedFAQ == faq.question {
                Text(faq.answer)
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textSecondary)
                    .padding(.horizontal, FuelSpacing.md)
                    .padding(.bottom, FuelSpacing.md)
            }
        }
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
    }

    // MARK: - Contact Section

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.sm) {
            Text("STILL NEED HELP?")
                .font(FuelTypography.caption)
                .foregroundStyle(FuelColors.textTertiary)

            VStack(spacing: 0) {
                contactRow(
                    icon: "envelope.fill",
                    title: "Email Support",
                    subtitle: "support@fuel.app",
                    action: {
                        if let url = URL(string: "mailto:support@fuel.app") {
                            UIApplication.shared.open(url)
                        }
                    }
                )

                Divider()
                    .padding(.leading, FuelSpacing.md + 32 + FuelSpacing.md)

                contactRow(
                    icon: "bubble.left.fill",
                    title: "Live Chat",
                    subtitle: "Available 9am-5pm PST",
                    action: {
                        // Open chat
                    }
                )
            }
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd))
        }
    }

    private func contactRow(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
            FuelHaptics.shared.tap()
        } label: {
            HStack(spacing: FuelSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(FuelColors.primary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                    Text(title)
                        .font(FuelTypography.subheadlineMedium)
                        .foregroundStyle(FuelColors.textPrimary)

                    Text(subtitle)
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FuelColors.textTertiary)
            }
            .padding(FuelSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FAQ Item

struct FAQItem {
    let question: String
    let answer: String
    let category: String
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HelpCenterView()
    }
}

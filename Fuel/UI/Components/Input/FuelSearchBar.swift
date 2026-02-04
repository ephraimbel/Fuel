import SwiftUI

/// Fuel Design System - Search Bar
/// Premium search input with suggestions and recent searches

public struct FuelSearchBar: View {
    let placeholder: String
    let showCancelButton: Bool
    let onSubmit: ((String) -> Void)?

    @Binding var text: String
    @FocusState private var isFocused: Bool
    @State private var isEditing = false

    public init(
        placeholder: String = "Search foods...",
        text: Binding<String>,
        showCancelButton: Bool = true,
        onSubmit: ((String) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.showCancelButton = showCancelButton
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: FuelSpacing.sm) {
            // Search field
            HStack(spacing: FuelSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(FuelColors.textSecondary)

                TextField(placeholder, text: $text)
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textPrimary)
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        onSubmit?(text)
                    }
                    .onChange(of: isFocused) { _, focused in
                        withAnimation(FuelAnimations.springQuick) {
                            isEditing = focused
                        }
                    }

                // Clear button
                if !text.isEmpty {
                    Button {
                        FuelHaptics.shared.tap()
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, FuelSpacing.md)
            .padding(.vertical, FuelSpacing.sm)
            .background(FuelColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous)
                    .stroke(isFocused ? FuelColors.primary : .clear, lineWidth: 2)
            )

            // Cancel button
            if showCancelButton && isEditing {
                Button {
                    FuelHaptics.shared.tap()
                    text = ""
                    isFocused = false
                } label: {
                    Text("Cancel")
                        .font(FuelTypography.body)
                        .foregroundStyle(FuelColors.primary)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(FuelAnimations.springQuick, value: text.isEmpty)
        .animation(FuelAnimations.spring, value: isEditing)
    }
}

// MARK: - Search Bar with Suggestions

public struct FuelSearchBarWithSuggestions: View {
    let placeholder: String
    let recentSearches: [String]
    let suggestions: [String]
    let onSelect: (String) -> Void
    let onClearRecent: () -> Void

    @Binding var text: String
    @FocusState private var isFocused: Bool
    @State private var showSuggestions = false

    public init(
        placeholder: String = "Search foods...",
        text: Binding<String>,
        recentSearches: [String] = [],
        suggestions: [String] = [],
        onSelect: @escaping (String) -> Void,
        onClearRecent: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        self._text = text
        self.recentSearches = recentSearches
        self.suggestions = suggestions
        self.onSelect = onSelect
        self.onClearRecent = onClearRecent
    }

    private var filteredSuggestions: [String] {
        guard !text.isEmpty else { return [] }
        return suggestions.filter { $0.localizedCaseInsensitiveContains(text) }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search bar
            FuelSearchBar(
                placeholder: placeholder,
                text: $text,
                onSubmit: { query in
                    onSelect(query)
                    isFocused = false
                }
            )
            .focused($isFocused)
            .onChange(of: isFocused) { _, focused in
                withAnimation(FuelAnimations.spring) {
                    showSuggestions = focused
                }
            }

            // Suggestions dropdown
            if showSuggestions {
                VStack(spacing: 0) {
                    // Recent searches
                    if text.isEmpty && !recentSearches.isEmpty {
                        recentSearchesSection
                    }

                    // Live suggestions
                    if !filteredSuggestions.isEmpty {
                        suggestionsSection
                    }
                }
                .background(FuelColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                .padding(.top, FuelSpacing.xs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Sections

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
                    .textCase(.uppercase)

                Spacer()

                Button {
                    FuelHaptics.shared.tap()
                    onClearRecent()
                } label: {
                    Text("Clear")
                        .font(FuelTypography.caption)
                        .foregroundStyle(FuelColors.primary)
                }
            }
            .padding(.horizontal, FuelSpacing.md)
            .padding(.vertical, FuelSpacing.sm)

            ForEach(recentSearches.prefix(5), id: \.self) { search in
                suggestionRow(
                    text: search,
                    icon: "clock",
                    isRecent: true
                )
            }
        }
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(filteredSuggestions.prefix(5), id: \.self) { suggestion in
                suggestionRow(
                    text: suggestion,
                    icon: "magnifyingglass",
                    isRecent: false
                )
            }
        }
    }

    private func suggestionRow(text: String, icon: String, isRecent: Bool) -> some View {
        Button {
            FuelHaptics.shared.select()
            self.text = text
            onSelect(text)
            isFocused = false
        } label: {
            HStack(spacing: FuelSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(FuelColors.textTertiary)
                    .frame(width: 20)

                Text(text)
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textPrimary)

                Spacer()

                if !isRecent {
                    Image(systemName: "arrow.up.left")
                        .font(.system(size: 12))
                        .foregroundStyle(FuelColors.textTertiary)
                }
            }
            .padding(.horizontal, FuelSpacing.md)
            .padding(.vertical, FuelSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Barcode Search Overlay

public struct BarcodeSearchOverlay: View {
    @Binding var isPresented: Bool
    let onScan: () -> Void

    public init(isPresented: Binding<Bool>, onScan: @escaping () -> Void) {
        self._isPresented = isPresented
        self.onScan = onScan
    }

    public var body: some View {
        HStack(spacing: FuelSpacing.md) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 24))
                .foregroundStyle(FuelColors.primary)

            VStack(alignment: .leading, spacing: FuelSpacing.xxxs) {
                Text("Scan Barcode")
                    .font(FuelTypography.headline)
                    .foregroundStyle(FuelColors.textPrimary)

                Text("Quickly add packaged foods")
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textSecondary)
            }

            Spacer()

            Button {
                FuelHaptics.shared.tap()
                onScan()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
        .padding(FuelSpacing.md)
        .background(FuelColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
    }
}

// MARK: - Preview

#Preview("Search Bars") {
    VStack(spacing: 24) {
        FuelSearchBar(text: .constant(""))

        FuelSearchBar(text: .constant("Chicken"))

        FuelSearchBarWithSuggestions(
            text: .constant(""),
            recentSearches: ["Chicken breast", "Brown rice", "Avocado"],
            suggestions: ["Chicken breast", "Chicken thigh", "Chicken wings"],
            onSelect: { _ in }
        )

        BarcodeSearchOverlay(isPresented: .constant(true)) {}
    }
    .padding()
}

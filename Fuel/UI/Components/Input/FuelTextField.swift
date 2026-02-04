import SwiftUI

/// Fuel Design System - Text Fields
/// Premium styled input fields with validation states

public struct FuelTextField: View {
    let label: String
    let placeholder: String
    let icon: String?
    let keyboardType: UIKeyboardType
    let isSecure: Bool
    let error: String?
    let helpText: String?

    @Binding var text: String
    @FocusState private var isFocused: Bool
    @State private var showSecureText = false

    public init(
        label: String,
        placeholder: String = "",
        icon: String? = nil,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false,
        error: String? = nil,
        helpText: String? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.icon = icon
        self._text = text
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.error = error
        self.helpText = helpText
    }

    private var hasError: Bool {
        error != nil
    }

    private var borderColor: Color {
        if hasError {
            return FuelColors.error
        } else if isFocused {
            return FuelColors.primary
        } else {
            return FuelColors.border
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.xs) {
            // Label
            Text(label)
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(hasError ? FuelColors.error : FuelColors.textPrimary)

            // Input field
            HStack(spacing: FuelSpacing.sm) {
                // Leading icon
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(hasError ? FuelColors.error : FuelColors.textSecondary)
                        .frame(width: 24)
                }

                // Text input
                if isSecure && !showSecureText {
                    SecureField(placeholder, text: $text)
                        .font(FuelTypography.body)
                        .foregroundStyle(FuelColors.textPrimary)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .font(FuelTypography.body)
                        .foregroundStyle(FuelColors.textPrimary)
                        .keyboardType(keyboardType)
                        .focused($isFocused)
                        .autocorrectionDisabled()
                }

                // Trailing buttons
                if !text.isEmpty && !isSecure {
                    Button {
                        FuelHaptics.shared.tap()
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(FuelColors.textTertiary)
                    }
                }

                if isSecure {
                    Button {
                        FuelHaptics.shared.tap()
                        showSecureText.toggle()
                    } label: {
                        Image(systemName: showSecureText ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(FuelColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, FuelSpacing.md)
            .padding(.vertical, FuelSpacing.sm + 2)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous)
                    .stroke(borderColor, lineWidth: isFocused || hasError ? 2 : 1)
            )
            .animation(FuelAnimations.springQuick, value: isFocused)
            .animation(FuelAnimations.springQuick, value: hasError)

            // Error or help text
            if let error {
                HStack(spacing: FuelSpacing.xxs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(FuelTypography.caption)
                }
                .foregroundStyle(FuelColors.error)
            } else if let helpText {
                Text(helpText)
                    .font(FuelTypography.caption)
                    .foregroundStyle(FuelColors.textTertiary)
            }
        }
    }
}

// MARK: - Numeric Field

/// Specialized text field for numeric input
public struct FuelNumericField: View {
    let label: String
    let placeholder: String
    let unit: String?
    let range: ClosedRange<Double>?

    @Binding var value: Double
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    public init(
        label: String,
        placeholder: String = "0",
        unit: String? = nil,
        value: Binding<Double>,
        range: ClosedRange<Double>? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.unit = unit
        self._value = value
        self.range = range
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.xs) {
            // Label
            Text(label)
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(FuelColors.textPrimary)

            // Input row
            HStack(spacing: FuelSpacing.sm) {
                TextField(placeholder, text: $textValue)
                    .font(FuelTypography.title2)
                    .foregroundStyle(FuelColors.textPrimary)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: textValue) { _, newValue in
                        if let doubleValue = Double(newValue) {
                            if let range {
                                value = min(max(doubleValue, range.lowerBound), range.upperBound)
                            } else {
                                value = doubleValue
                            }
                        }
                    }
                    .onAppear {
                        textValue = value == 0 ? "" : String(format: "%.1f", value)
                    }

                if let unit {
                    Text(unit)
                        .font(FuelTypography.body)
                        .foregroundStyle(FuelColors.textSecondary)
                }
            }
            .padding(.horizontal, FuelSpacing.md)
            .padding(.vertical, FuelSpacing.sm + 2)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous)
                    .stroke(isFocused ? FuelColors.primary : FuelColors.border, lineWidth: isFocused ? 2 : 1)
            )
        }
    }
}

// MARK: - Stepper Field

/// Numeric field with increment/decrement buttons
public struct FuelStepperField: View {
    let label: String
    let unit: String?
    let step: Double
    let range: ClosedRange<Double>

    @Binding var value: Double

    public init(
        label: String,
        unit: String? = nil,
        value: Binding<Double>,
        step: Double = 1,
        range: ClosedRange<Double>
    ) {
        self.label = label
        self.unit = unit
        self._value = value
        self.step = step
        self.range = range
    }

    private var canDecrement: Bool {
        value - step >= range.lowerBound
    }

    private var canIncrement: Bool {
        value + step <= range.upperBound
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.xs) {
            // Label
            Text(label)
                .font(FuelTypography.subheadlineMedium)
                .foregroundStyle(FuelColors.textPrimary)

            // Stepper row
            HStack {
                // Decrement button
                Button {
                    guard canDecrement else { return }
                    FuelHaptics.shared.select()
                    value -= step
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(canDecrement ? FuelColors.primary : FuelColors.textTertiary)
                        .frame(width: 44, height: 44)
                        .background(FuelColors.surfaceSecondary)
                        .clipShape(Circle())
                }
                .disabled(!canDecrement)

                Spacer()

                // Value display
                HStack(spacing: FuelSpacing.xxs) {
                    Text(step == 1 ? "\(Int(value))" : String(format: "%.1f", value))
                        .font(FuelTypography.title1)
                        .foregroundStyle(FuelColors.textPrimary)
                        .contentTransition(.numericText())

                    if let unit {
                        Text(unit)
                            .font(FuelTypography.body)
                            .foregroundStyle(FuelColors.textSecondary)
                    }
                }

                Spacer()

                // Increment button
                Button {
                    guard canIncrement else { return }
                    FuelHaptics.shared.select()
                    value += step
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(canIncrement ? FuelColors.primary : FuelColors.textTertiary)
                        .frame(width: 44, height: 44)
                        .background(FuelColors.surfaceSecondary)
                        .clipShape(Circle())
                }
                .disabled(!canIncrement)
            }
            .padding(FuelSpacing.sm)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
        }
        .animation(FuelAnimations.springQuick, value: value)
    }
}

// MARK: - Text Area

/// Multi-line text input
public struct FuelTextArea: View {
    let label: String
    let placeholder: String
    let maxLength: Int?

    @Binding var text: String
    @FocusState private var isFocused: Bool

    public init(
        label: String,
        placeholder: String = "",
        text: Binding<String>,
        maxLength: Int? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.maxLength = maxLength
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FuelSpacing.xs) {
            // Header
            HStack {
                Text(label)
                    .font(FuelTypography.subheadlineMedium)
                    .foregroundStyle(FuelColors.textPrimary)

                Spacer()

                if let maxLength {
                    Text("\(text.count)/\(maxLength)")
                        .font(FuelTypography.caption)
                        .foregroundStyle(text.count > maxLength ? FuelColors.error : FuelColors.textTertiary)
                }
            }

            // Text area
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(FuelTypography.body)
                        .foregroundStyle(FuelColors.textTertiary)
                        .padding(.horizontal, FuelSpacing.md)
                        .padding(.vertical, FuelSpacing.sm + 4)
                }

                TextEditor(text: $text)
                    .font(FuelTypography.body)
                    .foregroundStyle(FuelColors.textPrimary)
                    .padding(.horizontal, FuelSpacing.sm)
                    .padding(.vertical, FuelSpacing.xxs)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .onChange(of: text) { _, newValue in
                        if let maxLength, newValue.count > maxLength {
                            text = String(newValue.prefix(maxLength))
                        }
                    }
            }
            .frame(minHeight: 100)
            .background(FuelColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FuelSpacing.radiusMd, style: .continuous)
                    .stroke(isFocused ? FuelColors.primary : FuelColors.border, lineWidth: isFocused ? 2 : 1)
            )
        }
    }
}

// MARK: - Preview

#Preview("Text Fields") {
    ScrollView {
        VStack(spacing: 24) {
            FuelTextField(
                label: "Email",
                placeholder: "Enter your email",
                icon: "envelope",
                text: .constant(""),
                keyboardType: .emailAddress
            )

            FuelTextField(
                label: "Password",
                placeholder: "Enter password",
                icon: "lock",
                text: .constant("secret123"),
                isSecure: true
            )

            FuelTextField(
                label: "Username",
                placeholder: "Choose a username",
                text: .constant("john"),
                error: "Username is already taken"
            )

            FuelNumericField(
                label: "Weight",
                unit: "kg",
                value: .constant(70.5)
            )

            FuelStepperField(
                label: "Servings",
                unit: "servings",
                value: .constant(2),
                range: 0.5...10
            )

            FuelTextArea(
                label: "Notes",
                placeholder: "Add any notes about this meal...",
                text: .constant(""),
                maxLength: 200
            )
        }
        .padding()
    }
}

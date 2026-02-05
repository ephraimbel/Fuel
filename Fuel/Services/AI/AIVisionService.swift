import Foundation
import UIKit

/// AI Vision Service
/// Handles food photo analysis using GPT-4 Vision API

@Observable
public final class AIVisionService {
    // MARK: - Singleton

    public static let shared = AIVisionService()

    // MARK: - Configuration

    private let apiEndpoint = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o"

    // MARK: - API Key

    private var apiKey: String {
        Secrets.openAIAPIKey
    }

    /// Check if the service is properly configured
    public var isConfigured: Bool {
        Secrets.isOpenAIConfigured
    }

    // MARK: - State

    public private(set) var isAnalyzing = false
    public private(set) var lastError: AIVisionError?

    // MARK: - Initialization

    private init() {}

    // MARK: - Analysis

    /// Analyze a food photo and return estimated nutrition
    @MainActor
    public func analyzeFood(image: UIImage) async throws -> FoodAnalysisResult {
        guard !apiKey.isEmpty else {
            throw AIVisionError.apiKeyMissing
        }

        isAnalyzing = true
        lastError = nil

        defer { isAnalyzing = false }

        // Resize image for API (can be done off main thread for performance)
        let resizedImage = await Task.detached(priority: .userInitiated) {
            self.resizeImage(image, maxDimension: 1024)
        }.value

        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw AIVisionError.imageProcessingFailed
        }

        let base64Image = imageData.base64EncodedString()

        // Build request
        let request = try buildRequest(base64Image: base64Image)

        // Make API call with retry logic
        let (data, _) = try await performRequestWithRetry(request, maxRetries: 3)

        // Parse response
        let result = try parseResponse(data)

        return result
    }

    /// Perform API request with exponential backoff retry
    private func performRequestWithRetry(_ request: URLRequest, maxRetries: Int) async throws -> (Data, URLResponse) {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AIVisionError.invalidResponse
                }

                switch httpResponse.statusCode {
                case 200:
                    return (data, response)
                case 429:
                    // Rate limited - wait and retry
                    if attempt < maxRetries - 1 {
                        let delay = pow(2.0, Double(attempt)) // Exponential backoff: 1s, 2s, 4s
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    throw AIVisionError.rateLimited
                case 401:
                    throw AIVisionError.apiKeyMissing
                case 500...599:
                    // Server error - retry
                    if attempt < maxRetries - 1 {
                        let delay = pow(2.0, Double(attempt))
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    throw AIVisionError.apiError(statusCode: httpResponse.statusCode)
                default:
                    throw AIVisionError.apiError(statusCode: httpResponse.statusCode)
                }
            } catch let error as AIVisionError {
                throw error
            } catch {
                lastError = error
                if attempt < maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            }
        }

        throw AIVisionError.networkError(lastError ?? NSError(domain: "AIVision", code: -1))
    }

    /// Analyze multiple food items in a single image
    @MainActor
    public func analyzeMeal(image: UIImage) async throws -> MealAnalysisResult {
        let foodResult = try await analyzeFood(image: image)

        return MealAnalysisResult(
            items: foodResult.items,
            totalCalories: foodResult.items.reduce(0) { $0 + $1.calories },
            totalProtein: foodResult.items.reduce(0) { $0 + $1.protein },
            totalCarbs: foodResult.items.reduce(0) { $0 + $1.carbs },
            totalFat: foodResult.items.reduce(0) { $0 + $1.fat },
            confidence: foodResult.confidence,
            suggestedMealType: foodResult.suggestedMealType,
            rawResponse: foodResult.rawResponse
        )
    }

    // MARK: - Private Methods

    private func buildRequest(base64Image: String) throws -> URLRequest {
        guard let url = URL(string: apiEndpoint) else {
            throw AIVisionError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let prompt = """
        Analyze this food image and identify all visible food items. For each item, estimate:

        MACRONUTRIENTS:
        - Calories
        - Protein (g)
        - Carbohydrates (g)
        - Fat (g)

        MICRONUTRIENTS:
        - Fiber (g)
        - Sugar (g)
        - Sodium (mg)
        - Saturated Fat (g)
        - Cholesterol (mg)

        Also provide:
        - Your confidence level (0-100%) in the analysis
        - Suggested meal type (breakfast, lunch, dinner, or snack)

        Respond in JSON format:
        {
            "items": [
                {
                    "name": "Food name",
                    "serving_size": "100g",
                    "calories": 150,
                    "protein": 10.0,
                    "carbs": 20.0,
                    "fat": 5.0,
                    "fiber": 3.0,
                    "sugar": 5.0,
                    "sodium": 200,
                    "saturated_fat": 2.0,
                    "cholesterol": 15
                }
            ],
            "confidence": 85,
            "suggested_meal_type": "lunch",
            "notes": "Optional notes about the meal"
        }

        Be accurate with portions visible in the image. If unsure, provide conservative estimates.
        """

        let body: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "high"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 1000
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return request
    }

    private func parseResponse(_ data: Data) throws -> FoodAnalysisResult {
        struct OpenAIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = openAIResponse.choices.first?.message.content else {
            throw AIVisionError.emptyResponse
        }

        // Extract JSON from response (handle markdown code blocks)
        let jsonString = extractJSON(from: content)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIVisionError.parsingFailed
        }

        struct AnalysisResponse: Decodable {
            struct Item: Decodable {
                let name: String
                let serving_size: String
                let calories: Int
                let protein: Double
                let carbs: Double
                let fat: Double
                let fiber: Double?
                let sugar: Double?
                let sodium: Double?
                let saturated_fat: Double?
                let cholesterol: Double?
            }
            let items: [Item]
            let confidence: Int
            let suggested_meal_type: String?
            let notes: String?
        }

        let analysis = try JSONDecoder().decode(AnalysisResponse.self, from: jsonData)

        let items = analysis.items.map { item in
            AnalyzedFoodItem(
                name: item.name,
                servingSize: item.serving_size,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                fiber: item.fiber,
                sugar: item.sugar,
                sodium: item.sodium,
                saturatedFat: item.saturated_fat,
                cholesterol: item.cholesterol
            )
        }

        return FoodAnalysisResult(
            items: items,
            confidence: Double(analysis.confidence) / 100.0,
            suggestedMealType: MealType(rawValue: analysis.suggested_meal_type ?? "") ?? .snack,
            notes: analysis.notes,
            rawResponse: content
        )
    }

    private func extractJSON(from content: String) -> String {
        // Remove markdown code blocks if present
        var json = content
        if json.contains("```json") {
            json = json.replacingOccurrences(of: "```json", with: "")
        }
        if json.contains("```") {
            json = json.replacingOccurrences(of: "```", with: "")
        }
        return json.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)

        if ratio >= 1 {
            return image
        }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        // Use modern thread-safe UIGraphicsImageRenderer
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Models

public struct FoodAnalysisResult {
    public let items: [AnalyzedFoodItem]
    public let confidence: Double
    public let suggestedMealType: MealType
    public let notes: String?
    public let rawResponse: String
}

public struct MealAnalysisResult {
    public let items: [AnalyzedFoodItem]
    public let totalCalories: Int
    public let totalProtein: Double
    public let totalCarbs: Double
    public let totalFat: Double
    public let confidence: Double
    public let suggestedMealType: MealType
    public let rawResponse: String
}

public struct AnalyzedFoodItem: Identifiable {
    public let id = UUID()
    public let name: String
    public let servingSize: String
    public let calories: Int
    public let protein: Double
    public let carbs: Double
    public let fat: Double

    // Micronutrients
    public let fiber: Double?
    public let sugar: Double?
    public let sodium: Double?
    public let saturatedFat: Double?
    public let cholesterol: Double?

    /// Convert to FoodItem model
    public func toFoodItem() -> FoodItem {
        // Parse serving size
        let (size, unit) = parseServingSize(servingSize)

        return FoodItem(
            name: name,
            servingSize: size,
            servingUnit: unit,
            numberOfServings: 1,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            saturatedFat: saturatedFat,
            cholesterol: cholesterol,
            source: .aiScan
        )
    }

    private func parseServingSize(_ serving: String) -> (Double, String) {
        // Try to parse "100g", "1 cup", etc.
        let pattern = #"(\d+(?:\.\d+)?)\s*(.+)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: serving, range: NSRange(serving.startIndex..., in: serving)) {
            if let sizeRange = Range(match.range(at: 1), in: serving),
               let unitRange = Range(match.range(at: 2), in: serving) {
                let size = Double(serving[sizeRange]) ?? 100
                let unit = String(serving[unitRange]).trimmingCharacters(in: .whitespaces)
                return (size, unit)
            }
        }
        return (100, "g")
    }
}

// MARK: - Errors

public enum AIVisionError: LocalizedError {
    case apiKeyMissing
    case invalidURL
    case imageProcessingFailed
    case invalidResponse
    case emptyResponse
    case parsingFailed
    case rateLimited
    case apiError(statusCode: Int)
    case networkError(Error)
    case scanLimitReached

    public var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "API key is not configured"
        case .invalidURL:
            return "Invalid API endpoint"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .invalidResponse:
            return "Invalid response from server"
        case .emptyResponse:
            return "Empty response from AI"
        case .parsingFailed:
            return "Failed to parse AI response"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .apiError(let statusCode):
            return "API error (status \(statusCode))"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .scanLimitReached:
            return "Daily scan limit reached. Upgrade to Premium for unlimited scans."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .rateLimited:
            return "Wait a moment and try again"
        case .scanLimitReached:
            return "Upgrade to Premium for unlimited AI scans"
        case .networkError:
            return "Check your internet connection"
        default:
            return "Please try again"
        }
    }
}

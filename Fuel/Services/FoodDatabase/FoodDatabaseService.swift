import Foundation

/// Food Database Service
/// Looks up food products by barcode using Open Food Facts API

@Observable
public final class FoodDatabaseService {
    // MARK: - Singleton

    public static let shared = FoodDatabaseService()

    // MARK: - Configuration

    private let baseURL = "https://world.openfoodfacts.org/api/v2"
    private let userAgent = "Fuel iOS App - https://fuel.app"

    // MARK: - State

    public private(set) var isLoading = false
    public private(set) var lastError: FoodDatabaseError?

    // MARK: - Cache

    private var cache: [String: ScannedProduct] = [:]
    private let cacheExpiration: TimeInterval = 3600 // 1 hour

    // MARK: - Initialization

    private init() {}

    // MARK: - Barcode Lookup

    /// Look up a product by barcode
    public func lookupBarcode(_ barcode: String) async throws -> ScannedProduct {
        // Check cache first
        if let cached = cache[barcode] {
            return cached
        }

        isLoading = true
        lastError = nil

        defer { isLoading = false }

        // Build request
        guard let url = URL(string: "\(baseURL)/product/\(barcode).json") else {
            throw FoodDatabaseError.invalidBarcode
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FoodDatabaseError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw FoodDatabaseError.productNotFound
            }
            throw FoodDatabaseError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let product = try parseResponse(data, barcode: barcode)

        // Cache result
        cache[barcode] = product

        return product
    }

    /// Search products by name - searches USDA for generic foods and Open Food Facts for branded products
    public func searchProducts(query: String, page: Int = 1) async throws -> [ScannedProduct] {
        isLoading = true
        lastError = nil

        defer { isLoading = false }

        let searchTerm = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Search both APIs concurrently
        async let usdaResults = searchUSDA(query: query, page: page)
        async let offResults = searchOpenFoodFacts(query: query, page: page)

        // Combine results - USDA first (generic foods), then Open Food Facts (branded)
        var combined: [ScannedProduct] = []

        if let usda = try? await usdaResults {
            combined.append(contentsOf: usda)
        }

        if let off = try? await offResults {
            combined.append(contentsOf: off)
        }

        // Remove duplicates by name similarity
        var seen = Set<String>()
        combined = combined.filter { product in
            let key = product.name.lowercased()
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }

        // Sort by relevance - prioritize exact matches and names starting with search term
        combined.sort { a, b in
            let aName = a.name.lowercased()
            let bName = b.name.lowercased()

            // Exact match gets highest priority
            let aExact = aName == searchTerm
            let bExact = bName == searchTerm
            if aExact && !bExact { return true }
            if bExact && !aExact { return false }

            // Starts with search term gets next priority
            let aStarts = aName.hasPrefix(searchTerm)
            let bStarts = bName.hasPrefix(searchTerm)
            if aStarts && !bStarts { return true }
            if bStarts && !aStarts { return false }

            // First word matches search term
            let aFirstWord = aName.components(separatedBy: CharacterSet.alphanumerics.inverted).first ?? ""
            let bFirstWord = bName.components(separatedBy: CharacterSet.alphanumerics.inverted).first ?? ""
            let aFirstMatch = aFirstWord == searchTerm || aFirstWord.hasPrefix(searchTerm)
            let bFirstMatch = bFirstWord == searchTerm || bFirstWord.hasPrefix(searchTerm)
            if aFirstMatch && !bFirstMatch { return true }
            if bFirstMatch && !aFirstMatch { return false }

            // Shorter names (simpler foods) before longer names
            return aName.count < bName.count
        }

        return combined
    }

    // MARK: - USDA FoodData Central Search

    private func searchUSDA(query: String, page: Int) async throws -> [ScannedProduct] {
        let apiKey = Secrets.usdaAPIKey
        guard !apiKey.isEmpty else { return [] }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let pageSize = 15
        let offset = (page - 1) * pageSize

        guard let url = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search?api_key=\(apiKey)&query=\(encodedQuery)&pageSize=\(pageSize)&pageNumber=\(page)&dataType=Foundation,SR%20Legacy") else {
            return []
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return []
        }

        return try parseUSDAResponse(data)
    }

    private func parseUSDAResponse(_ data: Data) throws -> [ScannedProduct] {
        struct USDAResponse: Decodable {
            let foods: [USDAFood]
        }

        struct USDAFood: Decodable {
            let fdcId: Int
            let description: String
            let brandName: String?
            let brandOwner: String?
            let foodNutrients: [USDANutrient]
            let servingSize: Double?
            let servingSizeUnit: String?
        }

        struct USDANutrient: Decodable {
            let nutrientId: Int
            let nutrientName: String?
            let value: Double?
            let unitName: String?
        }

        let decoded = try JSONDecoder().decode(USDAResponse.self, from: data)

        return decoded.foods.compactMap { food in
            // Extract nutrients
            var calories = 0
            var protein = 0.0
            var carbs = 0.0
            var fat = 0.0
            var fiber: Double?
            var sugar: Double?

            for nutrient in food.foodNutrients {
                switch nutrient.nutrientId {
                case 1008: calories = Int(nutrient.value ?? 0) // Energy (kcal)
                case 1003: protein = nutrient.value ?? 0 // Protein
                case 1005: carbs = nutrient.value ?? 0 // Carbohydrates
                case 1004: fat = nutrient.value ?? 0 // Fat
                case 1079: fiber = nutrient.value // Fiber
                case 2000: sugar = nutrient.value // Sugars
                default: break
                }
            }

            // Format name nicely
            let name = food.description.capitalized
                .replacingOccurrences(of: ", Raw", with: "")
                .replacingOccurrences(of: ", Nfs", with: "")
                .trimmingCharacters(in: .whitespaces)

            return ScannedProduct(
                barcode: "usda-\(food.fdcId)",
                name: name,
                brand: food.brandName ?? food.brandOwner,
                imageURL: nil,
                servingSize: food.servingSize ?? 100,
                servingUnit: food.servingSizeUnit ?? "g",
                servingSizeDescription: nil,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber ?? 0,
                sugar: sugar ?? 0,
                sodium: 0,
                nutritionGrade: nil,
                category: nil,
                quantity: nil
            )
        }
    }

    // MARK: - Open Food Facts Search

    private func searchOpenFoodFacts(query: String, page: Int) async throws -> [ScannedProduct] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "\(baseURL)/search?search_terms=\(encodedQuery)&page=\(page)&page_size=10&json=1") else {
            return []
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return []
        }

        return try parseSearchResponse(data)
    }

    // MARK: - Response Parsing

    private func parseResponse(_ data: Data, barcode: String) throws -> ScannedProduct {
        struct OpenFoodFactsResponse: Decodable {
            let status: Int
            let product: ProductData?

            struct ProductData: Decodable {
                let product_name: String?
                let brands: String?
                let image_url: String?
                let image_front_url: String?
                let serving_size: String?
                let nutriments: Nutriments?
                let nutrition_grades: String?
                let categories: String?
                let quantity: String?

                struct Nutriments: Decodable {
                    // Per 100g values
                    let energy_kcal_100g: Double?
                    let energy_100g: Double?
                    let proteins_100g: Double?
                    let carbohydrates_100g: Double?
                    let fat_100g: Double?
                    let fiber_100g: Double?
                    let sugars_100g: Double?
                    let sodium_100g: Double?
                    let saturated_fat_100g: Double?

                    // Per serving values
                    let energy_kcal_serving: Double?
                    let proteins_serving: Double?
                    let carbohydrates_serving: Double?
                    let fat_serving: Double?
                    let fiber_serving: Double?
                    let sugars_serving: Double?

                    enum CodingKeys: String, CodingKey {
                        case energy_kcal_100g = "energy-kcal_100g"
                        case energy_100g = "energy_100g"
                        case proteins_100g = "proteins_100g"
                        case carbohydrates_100g = "carbohydrates_100g"
                        case fat_100g = "fat_100g"
                        case fiber_100g = "fiber_100g"
                        case sugars_100g = "sugars_100g"
                        case sodium_100g = "sodium_100g"
                        case saturated_fat_100g = "saturated-fat_100g"
                        case energy_kcal_serving = "energy-kcal_serving"
                        case proteins_serving = "proteins_serving"
                        case carbohydrates_serving = "carbohydrates_serving"
                        case fat_serving = "fat_serving"
                        case fiber_serving = "fiber_serving"
                        case sugars_serving = "sugars_serving"
                    }
                }
            }
        }

        let response = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)

        guard response.status == 1, let product = response.product else {
            throw FoodDatabaseError.productNotFound
        }

        // Get product name
        let name = product.product_name ?? "Unknown Product"

        // Parse serving size
        let (servingSize, servingUnit) = parseServingSize(product.serving_size)

        // Get nutrient values (prefer per-serving, fallback to per-100g)
        let nutriments = product.nutriments

        // Calculate calories (energy-kcal or convert from kJ)
        var calories: Int = 0
        if let kcal = nutriments?.energy_kcal_serving {
            calories = Int(kcal)
        } else if let kcal100g = nutriments?.energy_kcal_100g {
            calories = Int(kcal100g * servingSize / 100)
        } else if let kj = nutriments?.energy_100g {
            // Convert kJ to kcal (1 kcal = 4.184 kJ)
            calories = Int((kj / 4.184) * servingSize / 100)
        }

        // Get macros
        let protein = nutriments?.proteins_serving ?? (nutriments?.proteins_100g ?? 0) * servingSize / 100
        let carbs = nutriments?.carbohydrates_serving ?? (nutriments?.carbohydrates_100g ?? 0) * servingSize / 100
        let fat = nutriments?.fat_serving ?? (nutriments?.fat_100g ?? 0) * servingSize / 100
        let fiber = nutriments?.fiber_serving ?? (nutriments?.fiber_100g ?? 0) * servingSize / 100
        let sugar = nutriments?.sugars_serving ?? (nutriments?.sugars_100g ?? 0) * servingSize / 100
        let sodium = (nutriments?.sodium_100g ?? 0) * servingSize / 100 * 1000 // Convert to mg

        return ScannedProduct(
            barcode: barcode,
            name: name,
            brand: product.brands,
            imageURL: product.image_front_url ?? product.image_url,
            servingSize: servingSize,
            servingUnit: servingUnit,
            servingSizeDescription: product.serving_size,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            nutritionGrade: product.nutrition_grades,
            category: product.categories?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces),
            quantity: product.quantity
        )
    }

    private func parseSearchResponse(_ data: Data) throws -> [ScannedProduct] {
        struct SearchResponse: Decodable {
            let products: [ProductItem]

            struct ProductItem: Decodable {
                let code: String?
                let product_name: String?
                let brands: String?
                let image_front_url: String?
                let serving_size: String?
                let nutriments: Nutriments?

                struct Nutriments: Decodable {
                    let energy_kcal_100g: Double?
                    let proteins_100g: Double?
                    let carbohydrates_100g: Double?
                    let fat_100g: Double?

                    enum CodingKeys: String, CodingKey {
                        case energy_kcal_100g = "energy-kcal_100g"
                        case proteins_100g = "proteins_100g"
                        case carbohydrates_100g = "carbohydrates_100g"
                        case fat_100g = "fat_100g"
                    }
                }
            }
        }

        let response = try JSONDecoder().decode(SearchResponse.self, from: data)

        return response.products.compactMap { item in
            guard let barcode = item.code,
                  let name = item.product_name,
                  !name.isEmpty else {
                return nil
            }

            let (servingSize, servingUnit) = parseServingSize(item.serving_size)

            return ScannedProduct(
                barcode: barcode,
                name: name,
                brand: item.brands,
                imageURL: item.image_front_url,
                servingSize: servingSize,
                servingUnit: servingUnit,
                servingSizeDescription: item.serving_size,
                calories: Int(item.nutriments?.energy_kcal_100g ?? 0),
                protein: item.nutriments?.proteins_100g ?? 0,
                carbs: item.nutriments?.carbohydrates_100g ?? 0,
                fat: item.nutriments?.fat_100g ?? 0,
                fiber: 0,
                sugar: 0,
                sodium: 0,
                nutritionGrade: nil,
                category: nil,
                quantity: nil
            )
        }
    }

    private func parseServingSize(_ servingString: String?) -> (Double, String) {
        guard let serving = servingString else {
            return (100, "g")
        }

        // Try to parse "30g", "1 cup (240ml)", "2 pieces (50g)", etc.
        let pattern = #"(\d+(?:\.\d+)?)\s*(g|ml|oz|cup|piece|slice|serving)?"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: serving, range: NSRange(serving.startIndex..., in: serving)) {
            if let sizeRange = Range(match.range(at: 1), in: serving) {
                let size = Double(serving[sizeRange]) ?? 100
                var unit = "g"
                if let unitRange = Range(match.range(at: 2), in: serving) {
                    unit = String(serving[unitRange]).lowercased()
                }
                return (size, unit)
            }
        }

        return (100, "g")
    }

    // MARK: - Cache Management

    public func clearCache() {
        cache.removeAll()
    }
}

// MARK: - Models

public struct ScannedProduct: Identifiable, Equatable {
    public let id = UUID()
    public let barcode: String
    public let name: String
    public let brand: String?
    public let imageURL: String?
    public let servingSize: Double
    public let servingUnit: String
    public let servingSizeDescription: String?
    public let calories: Int
    public let protein: Double
    public let carbs: Double
    public let fat: Double
    public let fiber: Double
    public let sugar: Double
    public let sodium: Double
    public let nutritionGrade: String?
    public let category: String?
    public let quantity: String?

    /// Display name with brand
    public var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(brand) - \(name)"
        }
        return name
    }

    /// Formatted serving size
    public var formattedServingSize: String {
        if let description = servingSizeDescription {
            return description
        }
        return "\(Int(servingSize))\(servingUnit)"
    }

    /// Convert to FoodItem model
    public func toFoodItem(servings: Double = 1) -> FoodItem {
        let item = FoodItem(
            name: name,
            servingSize: servingSize,
            servingUnit: servingUnit,
            numberOfServings: servings,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            source: .barcode
        )

        item.brandName = brand
        item.barcode = barcode
        item.fiberPerServing = fiber
        item.sugarPerServing = sugar
        item.sodiumPerServing = sodium
        item.externalID = barcode
        item.isVerified = true

        return item
    }

    public static func == (lhs: ScannedProduct, rhs: ScannedProduct) -> Bool {
        lhs.barcode == rhs.barcode
    }
}

// MARK: - Errors

public enum FoodDatabaseError: LocalizedError {
    case invalidBarcode
    case invalidQuery
    case invalidResponse
    case productNotFound
    case apiError(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidBarcode:
            return "Invalid barcode format"
        case .invalidQuery:
            return "Invalid search query"
        case .invalidResponse:
            return "Invalid response from server"
        case .productNotFound:
            return "Product not found in database"
        case .apiError(let statusCode):
            return "Server error (status \(statusCode))"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse product data"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .productNotFound:
            return "Try scanning again or add the food manually"
        case .networkError:
            return "Check your internet connection"
        default:
            return "Please try again"
        }
    }
}

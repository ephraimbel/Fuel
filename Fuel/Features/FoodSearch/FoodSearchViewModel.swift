import SwiftUI
import Combine

/// Food Search View Model
/// Manages food search state, queries, and results

@Observable
final class FoodSearchViewModel {
    // MARK: - State

    var searchText = ""
    var searchResults: [FoodSearchItem] = []
    var recentSearches: [String] = []
    var recentFoods: [FoodSearchItem] = []
    var isSearching = false
    var hasSearched = false
    var error: FoodSearchError?

    // MARK: - Pagination

    var currentPage = 1
    var hasMoreResults = true
    var isLoadingMore = false

    // MARK: - Configuration

    private let debounceInterval: TimeInterval = 0.4
    private let minimumSearchLength = 2
    private let maxRecentSearches = 10
    private let maxRecentFoods = 20

    // MARK: - Private

    private var searchTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {
        loadRecentData()
    }

    // MARK: - Search

    func search() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard query.count >= minimumSearchLength else {
            searchResults = []
            hasSearched = false
            return
        }

        // Cancel previous search
        searchTask?.cancel()

        // Debounce search
        searchTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))

            guard !Task.isCancelled else { return }

            await performSearch(query: query, page: 1)
        }
    }

    func loadMoreResults() {
        guard hasMoreResults, !isLoadingMore, !searchText.isEmpty else { return }

        Task {
            await performSearch(query: searchText, page: currentPage + 1, append: true)
        }
    }

    private func performSearch(query: String, page: Int, append: Bool = false) async {
        if !append {
            await MainActor.run {
                isSearching = true
                error = nil
            }
        } else {
            await MainActor.run {
                isLoadingMore = true
            }
        }

        do {
            // Search Open Food Facts
            let products = try await FoodDatabaseService.shared.searchProducts(query: query, page: page)

            let items = products.map { product in
                FoodSearchItem(
                    id: product.barcode,
                    name: product.name,
                    brand: product.brand,
                    calories: product.calories,
                    servingSize: product.formattedServingSize,
                    protein: product.protein,
                    carbs: product.carbs,
                    fat: product.fat,
                    imageURL: product.imageURL,
                    source: .database,
                    barcode: product.barcode
                )
            }

            await MainActor.run {
                if append {
                    searchResults.append(contentsOf: items)
                } else {
                    searchResults = items
                    saveRecentSearch(query)
                }

                currentPage = page
                hasMoreResults = items.count >= 20
                isSearching = false
                isLoadingMore = false
                hasSearched = true
            }
        } catch {
            await MainActor.run {
                self.error = .searchFailed(error)
                isSearching = false
                isLoadingMore = false
                hasSearched = true
            }
        }
    }

    // MARK: - Recent Data

    func loadRecentData() {
        // Load recent searches from UserDefaults
        if let searches = UserDefaults.standard.array(forKey: "recentFoodSearches") as? [String] {
            recentSearches = searches
        }

        // Load recent foods from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "recentFoods"),
           let foods = try? JSONDecoder().decode([FoodSearchItem].self, from: data) {
            recentFoods = foods
        }
    }

    func saveRecentSearch(_ query: String) {
        var searches = recentSearches.filter { $0.lowercased() != query.lowercased() }
        searches.insert(query, at: 0)
        if searches.count > maxRecentSearches {
            searches = Array(searches.prefix(maxRecentSearches))
        }
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: "recentFoodSearches")
    }

    func saveRecentFood(_ food: FoodSearchItem) {
        var foods = recentFoods.filter { $0.id != food.id }
        foods.insert(food, at: 0)
        if foods.count > maxRecentFoods {
            foods = Array(foods.prefix(maxRecentFoods))
        }
        recentFoods = foods

        if let data = try? JSONEncoder().encode(foods) {
            UserDefaults.standard.set(data, forKey: "recentFoods")
        }
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "recentFoodSearches")
    }

    func clearRecentFoods() {
        recentFoods = []
        UserDefaults.standard.removeObject(forKey: "recentFoods")
    }

    func selectRecentSearch(_ query: String) {
        searchText = query
        search()
    }

    // MARK: - Reset

    func reset() {
        searchText = ""
        searchResults = []
        hasSearched = false
        currentPage = 1
        hasMoreResults = true
        error = nil
        searchTask?.cancel()
    }
}

// MARK: - Food Search Item

struct FoodSearchItem: Identifiable, Equatable {
    let id: String
    let name: String
    let brand: String?
    let calories: Int
    let servingSize: String
    let protein: Double
    let carbs: Double
    let fat: Double
    let imageURL: String?
    let source: FoodSource
    let barcode: String?

    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(name) - \(brand)"
        }
        return name
    }

    /// Convert to FoodItem for adding to meal
    func toFoodItem(servings: Double = 1) -> FoodItem {
        let item = FoodItem(
            name: name,
            servingSize: 100,
            servingUnit: "g",
            numberOfServings: servings,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            source: source
        )

        item.brandName = brand
        item.barcode = barcode
        item.externalID = id

        return item
    }

    static func == (lhs: FoodSearchItem, rhs: FoodSearchItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable Extension

extension FoodSearchItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, brand, calories, servingSize, protein, carbs, fat, imageURL, source, barcode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        brand = try container.decodeIfPresent(String.self, forKey: .brand)
        calories = try container.decode(Int.self, forKey: .calories)
        servingSize = try container.decode(String.self, forKey: .servingSize)
        protein = try container.decode(Double.self, forKey: .protein)
        carbs = try container.decode(Double.self, forKey: .carbs)
        fat = try container.decode(Double.self, forKey: .fat)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        source = try container.decode(FoodSource.self, forKey: .source)
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(brand, forKey: .brand)
        try container.encode(calories, forKey: .calories)
        try container.encode(servingSize, forKey: .servingSize)
        try container.encode(protein, forKey: .protein)
        try container.encode(carbs, forKey: .carbs)
        try container.encode(fat, forKey: .fat)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(barcode, forKey: .barcode)
    }
}

// MARK: - Food Search Error

enum FoodSearchError: LocalizedError {
    case searchFailed(Error)
    case noResults
    case networkError

    var errorDescription: String? {
        switch self {
        case .searchFailed(let error):
            return "Search failed: \(error.localizedDescription)"
        case .noResults:
            return "No foods found matching your search"
        case .networkError:
            return "Network error. Please check your connection."
        }
    }
}

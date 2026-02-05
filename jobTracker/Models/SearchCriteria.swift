import Foundation

/// Saved search preferences for job searching
struct SearchCriteria: Codable, Equatable {
    var query: String
    var location: String
    var remoteOnly: Bool
    var datePosted: DatePostedFilter

    init(
        query: String = "",
        location: String = "",
        remoteOnly: Bool = false,
        datePosted: DatePostedFilter = .all
    ) {
        self.query = query
        self.location = location
        self.remoteOnly = remoteOnly
        self.datePosted = datePosted
    }

    /// Loads saved search criteria from UserDefaults
    static func load() -> SearchCriteria {
        guard let data = UserDefaults.standard.data(forKey: "savedSearchCriteria"),
              let criteria = try? JSONDecoder().decode(SearchCriteria.self, from: data) else {
            return SearchCriteria()
        }
        return criteria
    }

    /// Saves search criteria to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "savedSearchCriteria")
        }
    }
}

enum DatePostedFilter: String, Codable, CaseIterable {
    case all = "all"
    case today = "today"
    case threeDays = "3days"
    case week = "week"
    case month = "month"

    var displayName: String {
        switch self {
        case .all: return "Any time"
        case .today: return "Today"
        case .threeDays: return "Last 3 days"
        case .week: return "This week"
        case .month: return "This month"
        }
    }

    var apiValue: String {
        return rawValue
    }
}

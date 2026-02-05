import Foundation

/// Represents a job fetched from the JSearch API
struct ScrapedJob: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let company: String
    let city: String
    let state: String
    let minSalary: Double?
    let maxSalary: Double?
    let applyLink: String
    let description: String
    let postedDate: Date?
    let employmentType: String?
    let source: JobSource

    var location: String {
        if city.isEmpty && state.isEmpty {
            return ""
        } else if city.isEmpty {
            return state
        } else if state.isEmpty {
            return city
        }
        return "\(city), \(state)"
    }

    var salaryRange: String {
        guard let min = minSalary, let max = maxSalary else {
            if let min = minSalary {
                return "$\(Int(min).formatted())"
            } else if let max = maxSalary {
                return "Up to $\(Int(max).formatted())"
            }
            return ""
        }
        return "$\(Int(min).formatted()) - $\(Int(max).formatted())"
    }

    /// Converts this scraped job to the app's Job model with wishlist status
    func toTrackerJob() -> Job {
        Job(
            company: company,
            role: title,
            location: location,
            salary: salaryRange,
            status: .wishlist,
            url: applyLink,
            notes: employmentType ?? ""
        )
    }
}

enum JobSource: String, Codable {
    case linkedin = "LinkedIn"
    case indeed = "Indeed"
    case glassdoor = "Glassdoor"
    case ziprecruiter = "ZipRecruiter"
    case unknown = "Unknown"

    init(from publisher: String?) {
        guard let publisher = publisher?.lowercased() else {
            self = .unknown
            return
        }
        if publisher.contains("linkedin") {
            self = .linkedin
        } else if publisher.contains("indeed") {
            self = .indeed
        } else if publisher.contains("glassdoor") {
            self = .glassdoor
        } else if publisher.contains("ziprecruiter") {
            self = .ziprecruiter
        } else {
            self = .unknown
        }
    }
}

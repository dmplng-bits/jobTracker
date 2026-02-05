import Foundation

/// Service for searching jobs using the JSearch API (RapidAPI)
class JobSearchService {
    static let shared = JobSearchService()

    private let baseURL = "https://jsearch.p.rapidapi.com/search"
    private let host = "jsearch.p.rapidapi.com"
    private let keyManager = APIKeyManager.shared

    private init() {}

    /// The currently active API key
    var activeKey: APIKey? {
        keyManager.activeKey
    }

    /// Searches for jobs using the JSearch API
    /// - Parameters:
    ///   - query: Job title or keywords to search for
    ///   - location: Location to search in (city, state, or country)
    ///   - remoteOnly: If true, only returns remote jobs
    ///   - datePosted: Filter for job posting date
    ///   - page: Page number for pagination (default: 1)
    /// - Returns: Array of ScrapedJob objects
    func searchJobs(
        query: String,
        location: String = "",
        remoteOnly: Bool = false,
        datePosted: DatePostedFilter = .all,
        page: Int = 1
    ) async throws -> [ScrapedJob] {
        guard let apiKeyString = keyManager.activeKeyString, !apiKeyString.isEmpty else {
            throw JobSearchError.missingAPIKey
        }

        var components = URLComponents(string: baseURL)
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "num_pages", value: "1")
        ]

        if !location.isEmpty {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }

        if remoteOnly {
            queryItems.append(URLQueryItem(name: "remote_jobs_only", value: "true"))
        }

        if datePosted != .all {
            queryItems.append(URLQueryItem(name: "date_posted", value: datePosted.apiValue))
        }

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw JobSearchError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKeyString, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue(host, forHTTPHeaderField: "X-RapidAPI-Host")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw JobSearchError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401, 403:
            throw JobSearchError.invalidAPIKey
        case 429:
            throw JobSearchError.rateLimitExceeded
        default:
            throw JobSearchError.serverError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(JSearchResponse.self, from: data)

        return apiResponse.data.map { job in
            ScrapedJob(
                id: UUID(),
                title: job.jobTitle ?? "Unknown Title",
                company: job.employerName ?? "Unknown Company",
                city: job.jobCity ?? "",
                state: job.jobState ?? "",
                minSalary: job.jobMinSalary,
                maxSalary: job.jobMaxSalary,
                applyLink: job.jobApplyLink ?? "",
                description: job.jobDescription ?? "",
                postedDate: parseDate(job.jobPostedAtDatetimeUtc),
                employmentType: job.jobEmploymentType,
                source: JobSource(from: job.jobPublisher)
            )
        }
    }

    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            return date
        }

        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
}

// MARK: - API Response Models

private struct JSearchResponse: Codable {
    let status: String
    let requestId: String?
    let data: [JSearchJob]

    enum CodingKeys: String, CodingKey {
        case status
        case requestId = "request_id"
        case data
    }
}

private struct JSearchJob: Codable {
    let jobTitle: String?
    let employerName: String?
    let jobCity: String?
    let jobState: String?
    let jobCountry: String?
    let jobMinSalary: Double?
    let jobMaxSalary: Double?
    let jobApplyLink: String?
    let jobDescription: String?
    let jobPostedAtDatetimeUtc: String?
    let jobEmploymentType: String?
    let jobPublisher: String?

    enum CodingKeys: String, CodingKey {
        case jobTitle = "job_title"
        case employerName = "employer_name"
        case jobCity = "job_city"
        case jobState = "job_state"
        case jobCountry = "job_country"
        case jobMinSalary = "job_min_salary"
        case jobMaxSalary = "job_max_salary"
        case jobApplyLink = "job_apply_link"
        case jobDescription = "job_description"
        case jobPostedAtDatetimeUtc = "job_posted_at_datetime_utc"
        case jobEmploymentType = "job_employment_type"
        case jobPublisher = "job_publisher"
    }
}

// MARK: - Errors

enum JobSearchError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case invalidURL
    case invalidResponse
    case rateLimitExceeded
    case serverError(statusCode: Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not configured. Please add your RapidAPI key in Settings."
        case .invalidAPIKey:
            return "Invalid API key. Please check your RapidAPI key in Settings."
        case .invalidURL:
            return "Failed to construct search URL."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .rateLimitExceeded:
            return "API rate limit exceeded. Free tier allows 500 requests/month."
        case .serverError(let statusCode):
            return "Server error (status code: \(statusCode))."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

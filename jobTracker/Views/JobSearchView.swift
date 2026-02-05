import SwiftUI

struct JobSearchView: View {
    @ObservedObject var store: JobStore
    @Environment(\.dismiss) private var dismiss

    @State private var criteria = SearchCriteria.load()
    @State private var results: [ScrapedJob] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var addedJobIds: Set<UUID> = []

    private let searchService = JobSearchService.shared
    @ObservedObject private var keyManager = APIKeyManager.shared

    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }

    // MARK: - macOS Layout

    #if os(macOS)
    private var macOSLayout: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Find Jobs")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.platformBackground)

            Divider()

            // Search Form
            searchForm
                .padding()

            Divider()

            // Results
            resultsList
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    #endif

    // MARK: - iOS Layout

    #if !os(macOS)
    private var iOSLayout: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchForm
                    .padding()

                Divider()

                resultsList
            }
            .navigationTitle("Find Jobs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    #endif

    // MARK: - Search Form

    private var searchForm: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Job title field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Job Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g., iOS Developer", text: $criteria.query)
                        .textFieldStyle(.roundedBorder)
                }

                // Location field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g., Seattle, WA", text: $criteria.location)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack(spacing: 16) {
                // Remote toggle
                Toggle("Remote only", isOn: $criteria.remoteOnly)
                    .toggleStyle(.switch)

                Spacer()

                // Date posted picker
                Picker("Posted", selection: $criteria.datePosted) {
                    ForEach(DatePostedFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 150)

                // API key selector
                if keyManager.keys.count > 1 {
                    apiKeyPicker
                }

                // Search button
                Button(action: performSearch) {
                    HStack {
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text("Search")
                    }
                    .frame(minWidth: 100)
                }
                .buttonStyle(.borderedProminent)
                .disabled(criteria.query.isEmpty || isSearching || keyManager.activeKey == nil)
            }

            // Active API key indicator
            if let activeKey = keyManager.activeKey {
                HStack {
                    Image(systemName: "key.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("Using: \(activeKey.label)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("No API key configured. Go to Settings to add one.")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }

            // Error message
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        Group {
            if results.isEmpty && !isSearching {
                emptyState
            } else if isSearching {
                loadingState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(results) { job in
                            JobResultCard(
                                job: job,
                                isAdded: addedJobIds.contains(job.id),
                                onAdd: { addJobToTracker(job) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "briefcase")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Search for jobs")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Enter a job title and location to find opportunities")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
            Spacer()
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching...")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - API Key Picker

    private var apiKeyPicker: some View {
        Menu {
            ForEach(keyManager.keys) { apiKey in
                Button(action: { keyManager.setActiveKey(apiKey) }) {
                    HStack {
                        Text(apiKey.label)
                        if apiKey.isActive {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "key.fill")
                    .font(.caption)
                Text(keyManager.activeKey?.label ?? "Select Key")
                    .font(.caption)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)
        }
    }

    // MARK: - Actions

    private func performSearch() {
        isSearching = true
        errorMessage = nil
        criteria.save()

        Task {
            do {
                let jobs = try await searchService.searchJobs(
                    query: criteria.query,
                    location: criteria.location,
                    remoteOnly: criteria.remoteOnly,
                    datePosted: criteria.datePosted
                )
                await MainActor.run {
                    results = jobs
                    isSearching = false
                    if jobs.isEmpty {
                        errorMessage = "No jobs found. Try different search criteria."
                    }
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func addJobToTracker(_ scrapedJob: ScrapedJob) {
        store.addScrapedJob(scrapedJob)
        addedJobIds.insert(scrapedJob.id)
    }
}

// MARK: - Job Result Card

struct JobResultCard: View {
    let job: ScrapedJob
    let isAdded: Bool
    let onAdd: () -> Void

    @State private var showingDescription = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // Title and company
                    Text(job.title)
                        .font(.headline)
                        .lineLimit(2)

                    Text(job.company)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Location and salary
                    HStack(spacing: 12) {
                        if !job.location.isEmpty {
                            Label(job.location, systemImage: "mappin")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if !job.salaryRange.isEmpty {
                            Label(job.salaryRange, systemImage: "dollarsign.circle")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }

                    // Source and employment type
                    HStack(spacing: 8) {
                        Text(job.source.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(sourceColor.opacity(0.15))
                            .foregroundColor(sourceColor)
                            .cornerRadius(4)

                        if let type = job.employmentType {
                            Text(type)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        if let date = job.postedDate {
                            Text(date, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Add button
                VStack(spacing: 8) {
                    Button(action: onAdd) {
                        Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(isAdded ? .green : .blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(isAdded)

                    if !job.applyLink.isEmpty {
                        Link(destination: URL(string: job.applyLink) ?? URL(string: "about:blank")!) {
                            Image(systemName: "arrow.up.right.square")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }

            // Expandable description
            if !job.description.isEmpty {
                Button(action: { showingDescription.toggle() }) {
                    HStack {
                        Text(showingDescription ? "Hide description" : "Show description")
                            .font(.caption)
                        Image(systemName: showingDescription ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                if showingDescription {
                    Text(job.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(10)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color.platformControlBackground)
        .cornerRadius(10)
    }

    private var sourceColor: Color {
        switch job.source {
        case .linkedin: return .blue
        case .indeed: return .purple
        case .glassdoor: return .green
        case .ziprecruiter: return .orange
        case .unknown: return .gray
        }
    }
}

#Preview {
    JobSearchView(store: JobStore())
}

//
//  ContentView.swift
//  jobTracker
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var store = JobStore()
    @State private var selectedJob: Job?
    @State private var showingAddSheet = false
    @State private var draggedJob: Job?
    @State private var showingJobSearch = false
    @State private var showingSettings = false

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var exportURL: URL?
    #endif

    var body: some View {
        #if os(macOS)
        macOSContent
        #else
        iOSContent
        #endif
    }

    // MARK: - macOS Content

    #if os(macOS)
    private var macOSContent: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            kanbanBoard
        }
        .background(Color.platformTextBackground.opacity(0.5))
        .sheet(isPresented: $showingAddSheet) {
            JobFormView(store: store, job: nil)
        }
        .sheet(item: $selectedJob) { job in
            JobFormView(store: store, job: job)
        }
        .sheet(isPresented: $store.showingConflictResolution) {
            ConflictResolutionView(store: store)
        }
        .sheet(isPresented: $showingJobSearch) {
            JobSearchView(store: store)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    #endif

    // MARK: - iOS Content

    #if os(iOS)
    private var iOSContent: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    if horizontalSizeClass == .regular {
                        // iPad: Show full kanban board
                        kanbanBoard
                    } else {
                        // iPhone: Horizontal scrolling kanban
                        ScrollView(.horizontal, showsIndicators: false) {
                            kanbanBoard
                                .frame(minWidth: geometry.size.width * 2.5)
                        }
                    }
                }
            }
            .background(Color.platformTextBackground.opacity(0.5))
            .navigationTitle("Job Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            showingJobSearch = true
                        } label: {
                            Label("Find Jobs", systemImage: "magnifyingglass")
                        }
                        Divider()
                        Button {
                            exportJobsForIOS()
                        } label: {
                            Label("Export Jobs", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            showingImportSheet = true
                        } label: {
                            Label("Import Jobs", systemImage: "square.and.arrow.down")
                        }
                        Divider()
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                JobFormView(store: store, job: nil)
            }
            .sheet(item: $selectedJob) { job in
                JobFormView(store: store, job: job)
            }
            .sheet(isPresented: $store.showingConflictResolution) {
                ConflictResolutionView(store: store)
            }
            .sheet(isPresented: $showingJobSearch) {
                JobSearchView(store: store)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .fileExporter(
                isPresented: $showingExportSheet,
                document: JobsDocument(jobs: store.jobs),
                contentType: .json,
                defaultFilename: "JobTrackerExport"
            ) { _ in }
            .fileImporter(
                isPresented: $showingImportSheet,
                allowedContentTypes: [.json]
            ) { result in
                if case .success(let url) = result {
                    store.importJobsFromURL(url, replace: false)
                }
            }
        }
    }

    private func exportJobsForIOS() {
        showingExportSheet = true
    }
    #endif

    // MARK: - Shared Views

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("🍎 iOS Job Tracker")
                    .font(.largeTitle.bold())
                Text("Seattle • Bay Area • East Coast")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 20) {
                StatBadge(label: "Total", value: store.jobs.count, color: .gray)
                StatBadge(label: "Applied", value: store.jobs.filter { $0.status != .wishlist }.count, color: .blue)
                StatBadge(label: "Interviewing", value: store.jobs.filter { $0.status == .interviewing }.count, color: .purple)
                StatBadge(label: "Offers", value: store.jobs.filter { $0.status == .offer }.count, color: .green)
            }

            #if os(macOS)
            Button(action: { showingJobSearch = true }) {
                Label("Find Jobs", systemImage: "magnifyingglass")
            }
            .buttonStyle(.bordered)

            Menu {
                Button("Export Jobs...") {
                    store.exportJobs()
                }
                Divider()
                Button("Import Jobs (Merge)...") {
                    store.importJobs(replace: false)
                }
                Button("Import Jobs (Replace All)...") {
                    store.importJobs(replace: true)
                }
            } label: {
                Label("Import/Export", systemImage: "square.and.arrow.up.on.square")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Button(action: { showingSettings = true }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)

            Button(action: { showingAddSheet = true }) {
                Label("Add Job", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            #endif
        }
        .padding()
        .background(Color.platformBackground)
    }

    private var kanbanBoard: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(JobStatus.allCases, id: \.self) { status in
                KanbanColumn(
                    status: status,
                    jobs: store.jobs(for: status),
                    draggedJob: $draggedJob,
                    onDrop: { job in
                        store.moveJob(job, to: status)
                    },
                    onSelect: { job in
                        selectedJob = job
                    },
                    onDelete: { job in
                        store.deleteJob(job)
                    },
                    onMove: { job, newStatus in
                        store.moveJob(job, to: newStatus)
                    }
                )
                .layoutPriority(status == .wishlist ? 1 : 0)
            }
        }
        .padding()
    }
}

// MARK: - Jobs Document for iOS Export

#if os(iOS)
struct JobsDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var jobs: [Job]

    init(jobs: [Job]) {
        self.jobs = jobs
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        jobs = try decoder.decode([Job].self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(jobs)
        return FileWrapper(regularFileWithContents: data)
    }
}
#endif

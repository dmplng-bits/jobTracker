//
//  JobStore.swift
//  jobTracker
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#endif

class JobStore: ObservableObject {
    @Published var jobs: [Job] = []
    @Published var showingConflictResolution = false

    private let storageService = FileStorageService.shared
    private let syncManager = CloudSyncManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupSyncManager()
        loadJobs()
    }

    // MARK: - Sync Setup

    private func setupSyncManager() {
        syncManager.onRemoteChange = { [weak self] remoteJobs in
            self?.handleRemoteChange(remoteJobs)
        }
        syncManager.startMonitoring()
    }

    private func handleRemoteChange(_ remoteJobs: [Job]) {
        let (merged, conflicts) = syncManager.detectConflicts(localJobs: jobs, remoteJobs: remoteJobs)

        if conflicts.isEmpty {
            // No conflicts, auto-merge
            jobs = merged
            saveJobs()
        } else {
            // Has conflicts, show resolution UI
            syncManager.conflicts = conflicts
            jobs = merged
            showingConflictResolution = true
        }
    }

    var pendingConflicts: [SyncConflict] {
        syncManager.conflicts
    }

    func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) {
        syncManager.resolveConflict(conflict, resolution: resolution, in: &jobs)
        saveJobs()

        if syncManager.conflicts.isEmpty {
            showingConflictResolution = false
        }
    }

    // MARK: - Data Operations

    func loadJobs() {
        if let loaded = storageService.loadJobs() {
            jobs = loaded
        }
    }

    func saveJobs() {
        storageService.saveJobs(jobs)
    }

    func addJob(_ job: Job) {
        var newJob = job
        newJob.lastModified = Date()
        jobs.append(newJob)
        saveJobs()
    }

    func updateJob(_ job: Job) {
        if let index = jobs.firstIndex(where: { $0.id == job.id }) {
            var updatedJob = job
            updatedJob.lastModified = Date()
            jobs[index] = updatedJob
            saveJobs()
        }
    }

    func deleteJob(_ job: Job) {
        jobs.removeAll { $0.id == job.id }
        saveJobs()
    }

    func moveJob(_ job: Job, to status: JobStatus) {
        if let index = jobs.firstIndex(where: { $0.id == job.id }) {
            jobs[index].status = status
            jobs[index].lastModified = Date()
            saveJobs()
        }
    }

    func jobs(for status: JobStatus) -> [Job] {
        jobs.filter { $0.status == status }
    }

    // MARK: - Import/Export

    #if os(macOS)
    func exportJobs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "JobTrackerExport.json"
        panel.title = "Export Jobs"
        panel.message = "Choose where to save your job data"

        if panel.runModal() == .OK, let url = panel.url {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            if let data = try? encoder.encode(jobs) {
                try? data.write(to: url)
            }
        }
    }

    func importJobs(replace: Bool = false) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.title = "Import Jobs"
        panel.message = "Select a JSON file to import"

        if panel.runModal() == .OK, let url = panel.url {
            importJobsFromURL(url, replace: replace)
        }
    }
    #endif

    func importJobsFromURL(_ url: URL, replace: Bool) {
        guard let imported = storageService.loadJobsFromURL(url) else { return }

        if replace {
            jobs = imported
        } else {
            // Merge: add jobs that don't already exist (by ID)
            let existingIDs = Set(jobs.map { $0.id })
            let newJobs = imported.filter { !existingIDs.contains($0.id) }
            jobs.append(contentsOf: newJobs)
        }
        saveJobs()
    }

}

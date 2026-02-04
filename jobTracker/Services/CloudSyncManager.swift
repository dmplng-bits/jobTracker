//
//  CloudSyncManager.swift
//  jobTracker
//

import Foundation
import Combine

struct SyncConflict: Identifiable {
    let id = UUID()
    let localJob: Job
    let remoteJob: Job
}

enum ConflictResolution {
    case keepLocal
    case keepRemote
    case keepBoth
}

class CloudSyncManager: ObservableObject {
    @Published var conflicts: [SyncConflict] = []
    @Published var isSyncing = false

    private var metadataQuery: NSMetadataQuery?
    private var cancellables = Set<AnyCancellable>()
    private let storageService = FileStorageService.shared

    var onRemoteChange: (([Job]) -> Void)?

    init() {
        setupMetadataQuery()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - iCloud Monitoring

    func startMonitoring() {
        guard storageService.isICloudAvailable else { return }
        metadataQuery?.start()
    }

    func stopMonitoring() {
        metadataQuery?.stop()
    }

    private func setupMetadataQuery() {
        guard storageService.isICloudAvailable else { return }

        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemFSNameKey, "JobTracker.json")

        NotificationCenter.default.publisher(for: .NSMetadataQueryDidUpdate, object: query)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleRemoteChange()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .NSMetadataQueryDidFinishGathering, object: query)
            .sink { [weak self] _ in
                self?.handleRemoteChange()
            }
            .store(in: &cancellables)

        self.metadataQuery = query
    }

    private func handleRemoteChange() {
        guard let iCloudURL = storageService.iCloudFileURL else { return }

        // Use file coordinator for safe access
        let coordinator = NSFileCoordinator()
        var error: NSError?

        coordinator.coordinate(readingItemAt: iCloudURL, options: .withoutChanges, error: &error) { url in
            guard let data = try? Data(contentsOf: url) else { return }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            guard let remoteJobs = try? decoder.decode([Job].self, from: data) else { return }

            DispatchQueue.main.async { [weak self] in
                self?.onRemoteChange?(remoteJobs)
            }
        }

        if let error = error {
            print("File coordination error: \(error)")
        }
    }

    // MARK: - Conflict Detection

    func detectConflicts(localJobs: [Job], remoteJobs: [Job]) -> ([Job], [SyncConflict]) {
        var mergedJobs: [Job] = []
        var detectedConflicts: [SyncConflict] = []

        let remoteJobsById = Dictionary(uniqueKeysWithValues: remoteJobs.map { ($0.id, $0) })

        var processedIds = Set<UUID>()

        // Process all local jobs
        for localJob in localJobs {
            processedIds.insert(localJob.id)

            if let remoteJob = remoteJobsById[localJob.id] {
                // Job exists on both sides
                if localJob == remoteJob {
                    // No changes, keep as is
                    mergedJobs.append(localJob)
                } else if localJob.lastModified > remoteJob.lastModified {
                    // Local is newer
                    mergedJobs.append(localJob)
                } else if remoteJob.lastModified > localJob.lastModified {
                    // Remote is newer
                    mergedJobs.append(remoteJob)
                } else {
                    // Same timestamp but different content - conflict
                    detectedConflicts.append(SyncConflict(localJob: localJob, remoteJob: remoteJob))
                    mergedJobs.append(localJob) // Temporarily keep local
                }
            } else {
                // Job only exists locally - could be new or deleted remotely
                // For now, keep local jobs (user can delete if needed)
                mergedJobs.append(localJob)
            }
        }

        // Add jobs that only exist remotely (new from other device)
        for remoteJob in remoteJobs {
            if !processedIds.contains(remoteJob.id) {
                mergedJobs.append(remoteJob)
            }
        }

        return (mergedJobs, detectedConflicts)
    }

    // MARK: - Conflict Resolution

    func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution, in jobs: inout [Job]) {
        switch resolution {
        case .keepLocal:
            // Already using local, nothing to change
            break

        case .keepRemote:
            if let index = jobs.firstIndex(where: { $0.id == conflict.localJob.id }) {
                jobs[index] = conflict.remoteJob
            }

        case .keepBoth:
            // Create a copy of the remote job with a new ID
            var duplicateJob = conflict.remoteJob
            duplicateJob.id = UUID()
            duplicateJob.company = "\(duplicateJob.company) (Copy)"
            duplicateJob.lastModified = Date()
            jobs.append(duplicateJob)
        }

        // Remove from conflicts list
        conflicts.removeAll { $0.id == conflict.id }
    }
}

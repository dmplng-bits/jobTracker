//
//  FileStorageService.swift
//  jobTracker
//

import Foundation

class FileStorageService {
    static let shared = FileStorageService()

    private let fileName = "JobTracker.json"

    private init() {}

    // MARK: - URL Helpers

    var localFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    var iCloudFileURL: URL? {
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            return nil
        }
        let documentsURL = containerURL.appendingPathComponent("Documents")

        // Create Documents directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        }

        return documentsURL.appendingPathComponent(fileName)
    }

    var activeFileURL: URL {
        iCloudFileURL ?? localFileURL
    }

    var isICloudAvailable: Bool {
        iCloudFileURL != nil
    }

    // MARK: - File Operations

    func loadJobs() -> [Job]? {
        let url = activeFileURL

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode([Job].self, from: data)
    }

    func saveJobs(_ jobs: [Job]) {
        let url = activeFileURL

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(jobs) else { return }

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save jobs: \(error)")
        }
    }

    func loadJobsFromURL(_ url: URL) -> [Job]? {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode([Job].self, from: data)
    }
}

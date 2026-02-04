//
//  ConflictResolutionView.swift
//  jobTracker
//

import SwiftUI

struct ConflictResolutionView: View {
    @ObservedObject var store: JobStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        #if os(macOS)
        macOSContent
        #else
        iOSContent
        #endif
    }

    #if os(macOS)
    private var macOSContent: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            if store.pendingConflicts.isEmpty {
                noConflictsView
            } else {
                conflictsList
            }

            Divider()

            footerView
        }
        .frame(width: 800, height: 600)
    }
    #endif

    #if os(iOS)
    private var iOSContent: some View {
        NavigationStack {
            Group {
                if store.pendingConflicts.isEmpty {
                    noConflictsView
                } else {
                    conflictsList
                }
            }
            .navigationTitle("Sync Conflicts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(!store.pendingConflicts.isEmpty)
                }
            }
        }
    }
    #endif

    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.icloud")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Sync Conflicts Detected")
                .font(.largeTitle.bold())

            Text("The same jobs were edited on multiple devices. Choose which version to keep.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var noConflictsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("All Conflicts Resolved")
                .font(.title.bold())

            Text("Your data is now in sync across all devices.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var conflictsList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(store.pendingConflicts) { conflict in
                    ConflictCard(conflict: conflict) { resolution in
                        store.resolveConflict(conflict, resolution: resolution)
                    }
                }
            }
            .padding()
        }
    }

    private var footerView: some View {
        HStack {
            Text("\(store.pendingConflicts.count) conflict(s) remaining")
                .font(.body)
                .foregroundColor(.secondary)

            Spacer()

            Button("Done") {
                dismiss()
            }
            .font(.body)
            .buttonStyle(.borderedProminent)
            .disabled(!store.pendingConflicts.isEmpty)
        }
        .padding()
    }
}

// MARK: - Conflict Card

struct ConflictCard: View {
    let conflict: SyncConflict
    let onResolve: (ConflictResolution) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(conflict.localJob.company)
                    .font(.title2.bold())
                Text("•")
                    .foregroundColor(.secondary)
                Text(conflict.localJob.role)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .top, spacing: 20) {
                // Local version
                VStack(alignment: .leading, spacing: 10) {
                    Label("This Device", systemImage: "iphone")
                        .font(.callout.bold())
                        .foregroundColor(.blue)

                    JobVersionView(job: conflict.localJob)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)

                // Remote version
                VStack(alignment: .leading, spacing: 10) {
                    Label("iCloud", systemImage: "icloud")
                        .font(.callout.bold())
                        .foregroundColor(.purple)

                    JobVersionView(job: conflict.remoteJob)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(10)
            }

            HStack(spacing: 16) {
                Button {
                    onResolve(.keepLocal)
                } label: {
                    Label("Keep Local", systemImage: "iphone")
                        .font(.body)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    onResolve(.keepRemote)
                } label: {
                    Label("Keep iCloud", systemImage: "icloud")
                        .font(.body)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    onResolve(.keepBoth)
                } label: {
                    Label("Keep Both", systemImage: "doc.on.doc")
                        .font(.body)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.platformControlBackground)
        .cornerRadius(12)
    }
}

// MARK: - Job Version View

struct JobVersionView: View {
    let job: Job

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent("Status", value: "\(job.status.emoji) \(job.status.rawValue)")
            LabeledContent("Location", value: job.location.isEmpty ? "—" : job.location)
            LabeledContent("Salary", value: job.salary.isEmpty ? "—" : job.salary)

            if !job.notes.isEmpty {
                Text("Notes: \(job.notes)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Text("Modified: \(job.lastModified.formatted(date: .abbreviated, time: .shortened))")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .font(.body)
    }
}

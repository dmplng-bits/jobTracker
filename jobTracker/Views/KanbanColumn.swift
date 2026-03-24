//
//  KanbanColumn.swift
//  jobTracker
//

import SwiftUI
import UniformTypeIdentifiers

struct KanbanColumn: View {
    let status: JobStatus
    let jobs: [Job]
    @Binding var draggedJob: Job?
    let onDrop: (Job) -> Void
    let onSelect: (Job) -> Void
    let onDelete: (Job) -> Void
    let onMove: (Job, JobStatus) -> Void

    @State private var isTargeted = false
    @State private var searchText = ""

    private var filteredJobs: [Job] {
        guard !searchText.isEmpty else { return jobs }
        return jobs.filter {
            $0.company.localizedCaseInsensitiveContains(searchText) ||
            $0.role.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Column Header
            HStack {
                Text("\(status.emoji) \(status.rawValue)")
                    .font(.title3.bold())
                Spacer()
                Text("\(jobs.count)")
                    .font(.body.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(status.color.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(status.color.opacity(0.15))
            .cornerRadius(10)

            // Search bar — visible whenever the column has items
            if !jobs.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.footnote)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }

            // Cards
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(filteredJobs) { job in
                        JobCard(job: job)
                            .onTapGesture { onSelect(job) }
                            #if os(macOS)
                            .onDrag {
                                draggedJob = job
                                return NSItemProvider(object: job.id.uuidString as NSString)
                            }
                            #endif
                            .contextMenu {
                                Button("Edit") { onSelect(job) }
                                Divider()
                                ForEach(JobStatus.allCases, id: \.self) { newStatus in
                                    if newStatus != job.status {
                                        Button("Move to \(newStatus.rawValue)") {
                                            onMove(job, newStatus)
                                        }
                                    }
                                }
                                Divider()
                                Button("Delete", role: .destructive) { onDelete(job) }
                            }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(minWidth: status == .wishlist ? 280 : 220, maxWidth: .infinity, maxHeight: .infinity)
        .padding(10)
        .background(isTargeted ? status.color.opacity(0.1) : Color.clear)
        .cornerRadius(12)
        #if os(macOS)
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            if let job = draggedJob {
                onDrop(job)
                draggedJob = nil
                return true
            }
            return false
        }
        #endif
    }
}

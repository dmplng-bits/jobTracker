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

            // Cards
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(jobs) { job in
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
        .frame(minWidth: status == .wishlist ? 280 : 220, maxWidth: .infinity)
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

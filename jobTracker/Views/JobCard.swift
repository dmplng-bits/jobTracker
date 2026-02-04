//
//  JobCard.swift
//  jobTracker
//

import SwiftUI

struct JobCard: View {
    let job: Job

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(job.company)
                .font(.title3.bold())
                .lineLimit(1)

            Text(job.role)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                if !job.location.isEmpty {
                    Label(job.location, systemImage: "mappin")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            if !job.salary.isEmpty {
                Text(job.salary)
                    .font(.callout.bold())
                    .foregroundColor(.green)
            }

            if !job.notes.isEmpty {
                Text(job.notes)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.platformControlBackground)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

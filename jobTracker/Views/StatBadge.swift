//
//  StatBadge.swift
//  jobTracker
//

import SwiftUI

struct StatBadge: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text("\(value)")
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

//
//  JobStatus.swift
//  jobTracker
//

import SwiftUI

enum JobStatus: String, Codable, CaseIterable {
    case wishlist = "Wishlist"
    case applied = "Applied"
    case interviewing = "Interviewing"
    case offer = "Offer"
    case rejected = "Rejected"

    var emoji: String {
        switch self {
        case .wishlist: return "🎯"
        case .applied: return "📤"
        case .interviewing: return "💬"
        case .offer: return "🎉"
        case .rejected: return "❌"
        }
    }

    var color: Color {
        switch self {
        case .wishlist: return .gray
        case .applied: return .blue
        case .interviewing: return .purple
        case .offer: return .green
        case .rejected: return .red.opacity(0.6)
        }
    }
}

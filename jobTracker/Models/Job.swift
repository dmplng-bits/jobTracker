//
//  Job.swift
//  jobTracker
//

import Foundation

struct Job: Identifiable, Codable, Equatable {
    var id: UUID
    var company: String
    var role: String
    var location: String
    var salary: String
    var status: JobStatus
    var url: String
    var notes: String
    var dateAdded: Date
    var lastModified: Date

    init(id: UUID = UUID(), company: String, role: String, location: String = "", salary: String = "", status: JobStatus = .wishlist, url: String = "", notes: String = "", dateAdded: Date = Date(), lastModified: Date = Date()) {
        self.id = id
        self.company = company
        self.role = role
        self.location = location
        self.salary = salary
        self.status = status
        self.url = url
        self.notes = notes
        self.dateAdded = dateAdded
        self.lastModified = lastModified
    }

    // Custom decoder to handle legacy data without lastModified field
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        company = try container.decode(String.self, forKey: .company)
        role = try container.decode(String.self, forKey: .role)
        location = try container.decode(String.self, forKey: .location)
        salary = try container.decode(String.self, forKey: .salary)
        status = try container.decode(JobStatus.self, forKey: .status)
        url = try container.decode(String.self, forKey: .url)
        notes = try container.decode(String.self, forKey: .notes)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified) ?? dateAdded
    }

    private enum CodingKeys: String, CodingKey {
        case id, company, role, location, salary, status, url, notes, dateAdded, lastModified
    }
}

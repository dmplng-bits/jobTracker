//
//  JobFormView.swift
//  jobTracker
//

import SwiftUI

struct JobFormView: View {
    @ObservedObject var store: JobStore
    let job: Job?
    @Environment(\.dismiss) var dismiss

    @State private var company = ""
    @State private var role = ""
    @State private var location = ""
    @State private var salary = ""
    @State private var status = JobStatus.wishlist
    @State private var url = ""
    @State private var notes = ""

    var isEditing: Bool { job != nil }

    var body: some View {
        #if os(macOS)
        macOSForm
        #else
        iOSForm
        #endif
    }

    #if os(macOS)
    private var macOSForm: some View {
        VStack(spacing: 0) {
            Text(isEditing ? "Edit Job" : "Add New Job")
                .font(.largeTitle.bold())
                .padding()

            Form {
                TextField("Company", text: $company)
                    .font(.title3)
                TextField("Role", text: $role)
                    .font(.title3)
                TextField("Location", text: $location)
                    .font(.title3)
                TextField("Salary Range", text: $salary)
                    .font(.title3)
                Picker("Status", selection: $status) {
                    ForEach(JobStatus.allCases, id: \.self) { s in
                        Text("\(s.emoji) \(s.rawValue)").tag(s)
                    }
                }
                .font(.title3)
                TextField("Job URL", text: $url)
                    .font(.title3)
                TextField("Notes", text: $notes, axis: .vertical)
                    .font(.title3)
                    .lineLimit(3...6)
            }
            .formStyle(.grouped)
            .padding()

            Divider()

            HStack {
                if isEditing {
                    Button("Delete", role: .destructive) {
                        if let job = job {
                            store.deleteJob(job)
                        }
                        dismiss()
                    }
                    .font(.body)
                }

                Spacer()

                if isEditing, let urlString = URL(string: url), !url.isEmpty {
                    Link("Open Link", destination: urlString)
                        .font(.body)
                        .buttonStyle(.bordered)
                }

                Button("Cancel") { dismiss() }
                    .font(.body)
                    .buttonStyle(.bordered)

                Button(isEditing ? "Save" : "Add Job") {
                    saveJob()
                    dismiss()
                }
                .font(.body)
                .buttonStyle(.borderedProminent)
                .disabled(company.isEmpty || role.isEmpty)
            }
            .padding()
        }
        .frame(width: 550, height: 520)
        .onAppear(perform: loadJobData)
    }
    #endif

    #if os(iOS)
    private var iOSForm: some View {
        NavigationStack {
            Form {
                Section("Job Details") {
                    TextField("Company", text: $company)
                    TextField("Role", text: $role)
                    TextField("Location", text: $location)
                    TextField("Salary Range", text: $salary)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(JobStatus.allCases, id: \.self) { s in
                            Text("\(s.emoji) \(s.rawValue)").tag(s)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Additional Info") {
                    TextField("Job URL", text: $url)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if isEditing, let urlString = URL(string: url), !url.isEmpty {
                    Section {
                        Link("Open Job Link", destination: urlString)
                    }
                }

                if isEditing {
                    Section {
                        Button("Delete Job", role: .destructive) {
                            if let job = job {
                                store.deleteJob(job)
                            }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Job" : "Add New Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveJob()
                        dismiss()
                    }
                    .disabled(company.isEmpty || role.isEmpty)
                }
            }
            .onAppear(perform: loadJobData)
        }
    }
    #endif

    private func loadJobData() {
        if let job = job {
            company = job.company
            role = job.role
            location = job.location
            salary = job.salary
            status = job.status
            url = job.url
            notes = job.notes
        }
    }

    private func saveJob() {
        if let existing = job {
            let updated = Job(
                id: existing.id,
                company: company,
                role: role,
                location: location,
                salary: salary,
                status: status,
                url: url,
                notes: notes,
                dateAdded: existing.dateAdded,
                lastModified: Date()
            )
            store.updateJob(updated)
        } else {
            let newJob = Job(
                company: company,
                role: role,
                location: location,
                salary: salary,
                status: status,
                url: url,
                notes: notes
            )
            store.addJob(newJob)
        }
    }
}

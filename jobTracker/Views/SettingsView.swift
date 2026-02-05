import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var keyManager = APIKeyManager.shared

    @State private var showingAddKey = false
    @State private var editingKey: APIKey?

    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }

    // MARK: - macOS Layout

    #if os(macOS)
    private var macOSLayout: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.platformBackground)

            Divider()

            Form {
                Section {
                    apiKeysSection
                } header: {
                    Text("API Keys")
                }

                Section {
                    apiInfoSection
                } header: {
                    Text("About JSearch API")
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .frame(width: 500, height: 500)
        .sheet(isPresented: $showingAddKey) {
            APIKeyEditorView(keyManager: keyManager, existingKey: nil)
        }
        .sheet(item: $editingKey) { key in
            APIKeyEditorView(keyManager: keyManager, existingKey: key)
        }
    }
    #endif

    // MARK: - iOS Layout

    #if !os(macOS)
    private var iOSLayout: some View {
        NavigationStack {
            Form {
                Section {
                    apiKeysSection
                } header: {
                    Text("API Keys")
                }

                Section {
                    apiInfoSection
                } header: {
                    Text("About JSearch API")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddKey) {
                APIKeyEditorView(keyManager: keyManager, existingKey: nil)
            }
            .sheet(item: $editingKey) { key in
                APIKeyEditorView(keyManager: keyManager, existingKey: key)
            }
        }
    }
    #endif

    // MARK: - API Keys Section

    private var apiKeysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if keyManager.keys.isEmpty {
                Text("No API keys configured")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(keyManager.keys) { apiKey in
                    APIKeyRow(
                        apiKey: apiKey,
                        isActive: apiKey.isActive,
                        onSelect: {
                            keyManager.setActiveKey(apiKey)
                        },
                        onEdit: {
                            editingKey = apiKey
                        },
                        onDelete: {
                            keyManager.deleteKey(apiKey)
                        }
                    )
                }
            }

            Divider()

            Button(action: { showingAddKey = true }) {
                Label("Add API Key", systemImage: "plus.circle")
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - API Info Section

    private var apiInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("The JSearch API provides access to job listings from LinkedIn, Indeed, Glassdoor, and ZipRecruiter.")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Label("Free tier: 500 requests/month per key", systemImage: "gift")
                Label("Add multiple keys for more requests", systemImage: "key.2.on.ring")
                Label("Paid plans available for higher limits", systemImage: "creditcard")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Divider()

            Link(destination: URL(string: "https://rapidapi.com/letscrape-6bRBa3QguO5/api/jsearch")!) {
                Label("Get your API key at RapidAPI", systemImage: "arrow.up.right.square")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - API Key Row

struct APIKeyRow: View {
    let apiKey: APIKey
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isActive ? .green : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(apiKey.label)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(maskedKey)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospaced()
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if isActive {
                Text("Active")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var maskedKey: String {
        let key = apiKey.key
        if key.count <= 8 {
            return String(repeating: "•", count: key.count)
        }
        let prefix = String(key.prefix(4))
        let suffix = String(key.suffix(4))
        return "\(prefix)••••••••\(suffix)"
    }
}

// MARK: - API Key Editor

struct APIKeyEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var keyManager: APIKeyManager

    let existingKey: APIKey?

    @State private var label: String = ""
    @State private var key: String = ""
    @State private var showingKey = false

    var isEditing: Bool { existingKey != nil }

    var body: some View {
        #if os(macOS)
        macOSEditor
        #else
        iOSEditor
        #endif
    }

    #if os(macOS)
    private var macOSEditor: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEditing ? "Edit API Key" : "Add API Key")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                editorFields
            }
            .padding()

            Spacer()

            Divider()

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(isEditing ? "Save" : "Add") {
                    saveKey()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 400, height: 280)
        .onAppear(perform: loadExistingKey)
    }
    #endif

    #if !os(macOS)
    private var iOSEditor: some View {
        NavigationStack {
            Form {
                editorFields
            }
            .navigationTitle(isEditing ? "Edit API Key" : "Add API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveKey()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .onAppear(perform: loadExistingKey)
    }
    #endif

    private var editorFields: some View {
        Group {
            VStack(alignment: .leading, spacing: 4) {
                Text("Label")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g., Personal, Work, Backup", text: $label)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("API Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Group {
                        if showingKey {
                            TextField("Enter your RapidAPI key", text: $key)
                        } else {
                            SecureField("Enter your RapidAPI key", text: $key)
                        }
                    }
                    .textFieldStyle(.roundedBorder)

                    Button(action: { showingKey.toggle() }) {
                        Image(systemName: showingKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var isValid: Bool {
        !label.trimmingCharacters(in: .whitespaces).isEmpty &&
        !key.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func loadExistingKey() {
        if let existing = existingKey {
            label = existing.label
            key = existing.key
        }
    }

    private func saveKey() {
        let trimmedLabel = label.trimmingCharacters(in: .whitespaces)
        let trimmedKey = key.trimmingCharacters(in: .whitespaces)

        if let existing = existingKey {
            var updated = existing
            updated.label = trimmedLabel
            updated.key = trimmedKey
            keyManager.updateKey(updated)
        } else {
            keyManager.addKey(label: trimmedLabel, key: trimmedKey)
        }
        dismiss()
    }
}

#Preview {
    SettingsView()
}

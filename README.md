# Job Tracker

A native SwiftUI application for tracking job applications with a Kanban-style board interface. Works on both macOS and iOS with iCloud sync support.

## Features

- **Kanban Board Interface** - Visualize your job search pipeline with drag-and-drop columns
- **Cross-Platform** - Native apps for macOS and iOS from a single codebase
- **iCloud Sync** - Automatically syncs data across your Apple devices
- **Conflict Resolution** - Handles sync conflicts with options to keep local, remote, or both versions
- **Import/Export** - Backup and restore your data as JSON files

## Job Statuses

Jobs flow through five stages:

| Status | Description |
|--------|-------------|
| Wishlist | Companies you're interested in |
| Applied | Applications submitted |
| Interviewing | Active interview processes |
| Offer | Received offers |
| Rejected | Applications that didn't work out |

## Data Model

Each job entry tracks:
- Company name
- Role/position
- Location
- Salary
- Application URL
- Notes
- Date added
- Last modified timestamp

## Architecture

```
jobTracker/
├── App/
│   └── jobTrackerApp.swift       # App entry point
├── Models/
│   ├── Job.swift                 # Job data model
│   └── JobStatus.swift           # Status enum with colors/emoji
├── Services/
│   ├── JobStore.swift            # Main data store (ObservableObject)
│   ├── FileStorageService.swift  # Local/iCloud file persistence
│   └── CloudSyncManager.swift    # iCloud sync & conflict detection
├── Views/
│   ├── ContentView.swift         # Main view with platform-specific layouts
│   ├── KanbanColumn.swift        # Column component for each status
│   ├── JobCard.swift             # Individual job card
│   ├── JobFormView.swift         # Add/edit job form
│   ├── ConflictResolutionView.swift  # Sync conflict UI
│   └── StatBadge.swift           # Statistics display component
└── Utilities/
    └── PlatformHelpers.swift     # Cross-platform helpers
```

## Requirements

- macOS 13.0+ / iOS 16.0+
- Xcode 15.0+
- Apple Developer account (for iCloud features)

## Building

1. Open `jobTracker.xcodeproj` in Xcode
2. Select your target device (macOS or iOS simulator/device)
3. Build and run (⌘R)

For iCloud sync, ensure you have the iCloud capability enabled in your Apple Developer account and update the container identifier.

## Data Storage

- **With iCloud**: Data stored in `~/Library/Mobile Documents/iCloud~[bundle-id]/Documents/JobTracker.json`
- **Without iCloud**: Data stored in the app's Documents directory as `JobTracker.json`

## License

MIT

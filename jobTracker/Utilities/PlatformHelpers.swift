//
//  PlatformHelpers.swift
//  jobTracker
//

import SwiftUI

#if os(macOS)
import AppKit

let platformBackgroundColor = NSColor.windowBackgroundColor
let platformControlBackgroundColor = NSColor.controlBackgroundColor
let platformTextBackgroundColor = NSColor.textBackgroundColor

#else
import UIKit

let platformBackgroundColor = UIColor.systemBackground
let platformControlBackgroundColor = UIColor.secondarySystemBackground
let platformTextBackgroundColor = UIColor.tertiarySystemBackground

#endif

extension Color {
    static var platformBackground: Color {
        Color(platformBackgroundColor)
    }

    static var platformControlBackground: Color {
        Color(platformControlBackgroundColor)
    }

    static var platformTextBackground: Color {
        Color(platformTextBackgroundColor)
    }
}

// main.swift
// MarkDisplayApp
//
// Entry point. Uses a manual NSApplicationMain call so we can avoid the
// @NSApplicationMain attribute and keep AppDelegate in its own file.
//
// TODO: No logic needed here beyond bootstrapping NSApplication.

import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

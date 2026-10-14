# MarkDisplayApp

A menu-bar macOS app (AppKit, Swift) that draws a transparent overlay over the whole screen so you can annotate on top of any app.

## Build and run

Requires Xcode 15+ and macOS 13+.

```
open MarkDisplayApp/MarkDisplayApp.xcodeproj
```

Select the `MarkDisplayApp` scheme and run. A pencil icon appears in the menu bar (no Dock icon).

## Shortcuts

| Shortcut | Action |
|---|---|
| ^A | Toggle annotation (works from any app) |
| ^X | Clear canvas (works from any app) |
| F / H / E | Pen / highlighter / eraser (while annotating) |
| R / C / A | Rectangle / circle / arrow shape |
| Tab | Cycle to the next tool (pen, highlighter, shape, eraser) |
| [ / ] | Decrease / increase stroke width |
| 1–5 | Pick favourite colour slot |
| ⌘Z / ⌘⇧Z | Undo / redo |
| Esc | Stop annotating |

Colours, stroke width and auto-erase are set in **Preferences** (⌘,).

## Tests

From the `MarkDisplayApp/` directory:

```
swiftc -target arm64-apple-macos13.0 -sdk $(xcrun --show-sdk-path) \
  $(find MarkDisplayApp -name '*.swift' ! -path '*/App/main.swift') \
  Tests/main.swift -o /tmp/history-tests && /tmp/history-tests
```

## Adding features

- New drawing tool: add a case to `ToolType`, conform to `DrawingTool`, register it in `AnnotationCanvasView.tools`.
- Cursor highlight, spotlight, zoom, whiteboard: give each its own window controller next to `OverlayWindowController` and a menu item in `MenuBarController`. `AnnotationCanvasView` does not change.

## Known limits

- Main display only.
- No text tool (deferred).

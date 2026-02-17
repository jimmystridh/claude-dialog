import AppKit
import SwiftUI

@MainActor
enum DialogWindow {
    static func create(coordinator: DialogCoordinator) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 400),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.title = "Claude Code"
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true

        let hostingView = NSHostingView(rootView:
            DialogView(coordinator: coordinator)
                .frame(width: 460)
                .frame(maxHeight: 700)
                .fixedSize(horizontal: false, vertical: true)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )

        panel.contentView = hostingView
        panel.center()

        // Escape key closes
        panel.standardWindowButton(.closeButton)?.isHidden = true

        return panel
    }
}

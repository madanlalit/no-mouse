import AppKit
import SwiftUI

/// Manages the transparent overlay window that displays the grid
@MainActor
final class OverlayWindowController: NSObject, ObservableObject {
    
    private var overlayWindow: NSWindow?
    private var hostingView: NSHostingView<GridOverlayView>?
    
    @Published var isVisible: Bool = false
    @Published var highlightedRow: Int?
    @Published var refinementBounds: CGRect?  // Bounds for sub-grid in refinement mode
    
    private var gridCalculator: GridCalculator {
        GridCalculator(screenBounds: NSScreen.main?.frame ?? .zero)
    }
    
    override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Show the overlay window with grid
    func show() {
        refinementBounds = nil  // Reset refinement on show
        
        guard overlayWindow == nil else {
            overlayWindow?.orderFrontRegardless()
            isVisible = true
            updateOverlayContent()
            return
        }
        
        createOverlayWindow()
        overlayWindow?.orderFrontRegardless()
        isVisible = true
        print("[NoMouse] Overlay shown")
    }
    
    /// Hide the overlay window
    func hide() {
        overlayWindow?.orderOut(nil)
        isVisible = false
        highlightedRow = nil
        refinementBounds = nil
        print("[NoMouse] Overlay hidden")
    }
    
    /// Enter refinement mode - show sub-grid in the specified cell
    func enterRefinement(cellBounds: CGRect) {
        refinementBounds = cellBounds
        highlightedRow = nil
        updateOverlayContent()
        print("[NoMouse] Entered refinement mode at \(cellBounds)")
    }
    
    /// Exit refinement mode back to full grid
    func exitRefinement() {
        refinementBounds = nil
        updateOverlayContent()
    }
    
    /// Update highlighted row when first letter is typed
    func highlightRow(for letter: Character?) {
        if let letter = letter {
            let index = Int(letter.asciiValue ?? 65) - 65
            highlightedRow = (index >= 0 && index < 26) ? index : nil
        } else {
            highlightedRow = nil
        }
        updateOverlayContent()
    }
    
    // MARK: - Private Methods
    
    private func createOverlayWindow() {
        guard let screen = NSScreen.main else { return }
        
        // Create window covering entire screen
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties
        // Use screenSaver level to appear above menu bar and Dock
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true  // Click-through
        window.collectionBehavior = [
            .canJoinAllSpaces,      // Visible on all Spaces
            .stationary,            // Doesn't move with Mission Control
            .fullScreenAuxiliary    // Can appear over full-screen apps
        ]
        
        // Create SwiftUI content
        let gridView = GridOverlayView(
            gridCalculator: gridCalculator,
            highlightedRow: highlightedRow,
            refinementBounds: refinementBounds
        )
        
        let hostingView = NSHostingView(rootView: gridView)
        hostingView.frame = screen.frame
        
        window.contentView = hostingView
        self.hostingView = hostingView
        self.overlayWindow = window
    }
    
    private func updateOverlayContent() {
        guard let hostingView = hostingView else { return }
        hostingView.rootView = GridOverlayView(
            gridCalculator: gridCalculator,
            highlightedRow: highlightedRow,
            refinementBounds: refinementBounds
        )
    }
    
    /// Update window frame when screen changes
    func updateScreenBounds() {
        guard let screen = NSScreen.main, let window = overlayWindow else { return }
        window.setFrame(screen.frame, display: true)
        updateOverlayContent()
    }
}

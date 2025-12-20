import Foundation
import Combine
import CoreGraphics

/// Application state machine for NoMouse
/// Controls the current mode of operation
enum AppMode: String, CaseIterable, Sendable {
    case idle = "Idle"
    case gridActive = "Grid Active"
    case gridRefinement = "Grid Refinement"  // Sub-grid for precision
    case freeMove = "Free Move"  // Phase 2
}

/// Thread-safe activation settings
/// These need to be accessed from the event tap callback (non-main thread)
struct ActivationSettings: Sendable {
    var modifiers: CGEventFlags = .maskControl
    var keyCode: CGKeyCode = 49  // Space key
}

/// Observable state container for the application
@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentMode: AppMode = .idle
    @Published var isEnabled: Bool = true  // Global enable/disable
    
    /// First letter of two-letter grid input
    @Published private(set) var firstGridLetter: Character?
    
    /// Current cursor position (for display purposes)
    @Published private(set) var cursorPosition: CGPoint = .zero
    
    /// Selected cell from first grid (for refinement mode)
    @Published private(set) var selectedCell: String?
    
    /// Bounds of the selected cell (for sub-grid)
    @Published private(set) var selectedCellBounds: CGRect?
    
    // MARK: - Movement Settings
    
    /// Base movement speed in pixels per keypress
    @Published var movementSpeed: CGFloat = 10
    
    /// Fast movement multiplier (when holding Shift)
    @Published var fastMultiplier: CGFloat = 5
    
    /// Slow/precise movement divisor (when holding Option/Alt)
    @Published var slowDivisor: CGFloat = 5
    
    /// Scroll speed in pixels per scroll event
    @Published var scrollSpeed: Int32 = 50
    
    /// Drag mode active (mouse button held down while moving)
    @Published private(set) var isDragging: Bool = false
    
    // MARK: - Thread-Safe Settings
    
    /// Activation settings accessed from event tap (nonisolated)
    nonisolated let activationSettings = ActivationSettings()
    
    /// Thread-safe check if app is active (uses atomic)
    private let _isActiveAtomic = AtomicBool(false)
    
    // MARK: - Mode Transitions
    
    func activateGridMode() {
        guard currentMode == .idle else { return }
        currentMode = .gridActive
        firstGridLetter = nil
        selectedCell = nil
        selectedCellBounds = nil
        _isActiveAtomic.store(true)
        print("[NoMouse] Grid mode activated")
    }
    
    func enterRefinementMode(cell: String, bounds: CGRect) {
        currentMode = .gridRefinement
        selectedCell = cell
        selectedCellBounds = bounds
        firstGridLetter = nil
        print("[NoMouse] Refinement mode: \(cell) at \(bounds)")
    }
    
    func deactivate() {
        currentMode = .idle
        firstGridLetter = nil
        selectedCell = nil
        selectedCellBounds = nil
        _isActiveAtomic.store(false)
        print("[NoMouse] Deactivated, returning to idle")
    }
    
    /// Go back from refinement to full grid
    func backToFullGrid() {
        currentMode = .gridActive
        selectedCell = nil
        selectedCellBounds = nil
        firstGridLetter = nil
        print("[NoMouse] Back to full grid")
    }
    
    /// Enter free movement mode (arrow keys/HJKL control)
    func enterFreeMove() {
        currentMode = .freeMove
        selectedCell = nil
        selectedCellBounds = nil
        firstGridLetter = nil
        print("[NoMouse] Entered free move mode")
    }
    
    /// Toggle between grid and free move modes
    func toggleFreeMove() {
        if currentMode == .freeMove {
            currentMode = .gridActive
            print("[NoMouse] Switched to grid mode")
        } else if currentMode == .gridActive || currentMode == .gridRefinement {
            enterFreeMove()
        }
    }
    
    func setFirstGridLetter(_ letter: Character) {
        firstGridLetter = letter
        print("[NoMouse] First letter: \(letter)")
    }
    
    func clearFirstGridLetter() {
        firstGridLetter = nil
    }
    
    func updateCursorPosition(_ point: CGPoint) {
        cursorPosition = point
    }
    
    // MARK: - Drag Mode
    
    func startDrag() {
        isDragging = true
        print("[NoMouse] Drag started")
    }
    
    func stopDrag() {
        isDragging = false
        print("[NoMouse] Drag stopped")
    }
    
    func toggleDrag() {
        if isDragging {
            stopDrag()
        } else {
            startDrag()
        }
    }
    
    // MARK: - State Queries
    
    var isActive: Bool {
        currentMode != .idle
    }
    
    var isInRefinementMode: Bool {
        currentMode == .gridRefinement
    }
    
    /// Thread-safe isActive check for event tap
    nonisolated var isActiveNonisolated: Bool {
        _isActiveAtomic.load()
    }
    
    var statusText: String {
        guard isEnabled else { return "Disabled" }
        switch currentMode {
        case .idle:
            return "Ready (⌃ Space to activate)"
        case .gridActive:
            if let first = firstGridLetter {
                return "Grid: \(first)_"
            }
            return "Grid: Type 2 letters"
        case .gridRefinement:
            if let cell = selectedCell {
                if let first = firstGridLetter {
                    return "Refine \(cell): \(first)_"
                }
                return "Refine \(cell): Type 2 letters"
            }
            return "Refinement mode"
        case .freeMove:
            return "Free Move (↑↓←→ or HJKL)"
        }
    }
}

// MARK: - Thread-safe atomic boolean

/// Simple atomic boolean using lock
final class AtomicBool: @unchecked Sendable {
    private var value: Bool
    private let lock = NSLock()
    
    init(_ value: Bool) {
        self.value = value
    }
    
    func store(_ newValue: Bool) {
        lock.lock()
        value = newValue
        lock.unlock()
    }
    
    func load() -> Bool {
        lock.lock()
        let result = value
        lock.unlock()
        return result
    }
}

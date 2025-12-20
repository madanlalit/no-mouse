import Foundation
import CoreGraphics
import AppKit
import Combine

/// Handles global keyboard event interception using CGEvent taps
/// Security Note: Events are processed and immediately discarded, never stored
final class KeyboardEventController {
    
    // MARK: - Dependencies
    
    private let appState: AppState
    private let mouseController: MouseController
    private var gridCalculator: GridCalculator
    private var singleLetterGrid: SingleLetterGrid?  // For single-letter refinement
    
    // MARK: - Event Tap State
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    // MARK: - Callbacks
    
    var onGridActivated: (() -> Void)?
    var onGridDeactivated: (() -> Void)?
    var onRefinementEntered: ((CGRect) -> Void)?  // Called when entering refinement with cell bounds
    var onCursorMoved: ((CGPoint) -> Void)?
    
    // MARK: - Acceleration State
    
    private var lastMoveTime: Date = Date.distantPast
    private var lastMoveDirection: MovementDirection?
    private var currentAcceleration: CGFloat = 1.0
    private let accelerationIncrement: CGFloat = 0.5  // Add 50% speed each repeat
    private let maxAcceleration: CGFloat = 10.0       // Cap at 10x speed
    private let accelerationTimeout: TimeInterval = 0.15  // Reset if >150ms between presses
    
    // MARK: - Initialization
    
    init(appState: AppState, mouseController: MouseController) {
        self.appState = appState
        self.mouseController = mouseController
        self.gridCalculator = GridCalculator(screenBounds: NSScreen.main?.frame ?? .zero)
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// Start listening for keyboard events
    func start() -> Bool {
        guard eventTap == nil else {
            print("[NoMouse] Event tap already running")
            return true
        }
        
        // Events we want to intercept
        let eventMask: CGEventMask = (
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)
        )
        
        // Create the event tap
        // Note: We use a global function callback because CGEventTapCallBack cannot be a method
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Recover the controller from refcon
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let controller = Unmanaged<KeyboardEventController>.fromOpaque(refcon).takeUnretainedValue()
                return controller.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("[NoMouse] Failed to create event tap - check Accessibility permissions")
            return false
        }
        
        eventTap = tap
        
        // Create run loop source and add to current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the tap
        CGEvent.tapEnable(tap: tap, enable: true)
        
        print("[NoMouse] Keyboard event tap started")
        return true
    }
    
    /// Stop listening for keyboard events
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
            // Note: CFMachPort is automatically invalidated when its last reference is released
        }
        eventTap = nil
        runLoopSource = nil
        print("[NoMouse] Keyboard event tap stopped")
    }
    
    /// Update grid calculator for current screen
    func updateScreenBounds() {
        gridCalculator = GridCalculator(screenBounds: NSScreen.main?.frame ?? .zero)
    }
    
    // MARK: - Event Handling
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Handle tap disabled events (can happen if system disables it)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }
        
        // Only process key events
        guard type == .keyDown || type == .keyUp || type == .flagsChanged else {
            return Unmanaged.passRetained(event)
        }
        
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        
        // Get activation settings (nonisolated access)
        let settings = appState.activationSettings
        
        // Check for activation shortcut (Control + Space on keyDown)
        if type == .keyDown && keyCode == settings.keyCode {
            if flags.contains(settings.modifiers) && !appState.isActiveNonisolated {
                let gridEnabled = appState.isGridModeEnabledNonisolated
                let freeMoveEnabled = appState.isFreeMoveEnabledNonisolated
                
                // Activate based on enabled modes
                Task { @MainActor in
                    if gridEnabled {
                        // Start with grid mode
                        self.appState.activateGridMode()
                        self.onGridActivated?()
                    } else if freeMoveEnabled {
                        // Start with free move mode (no grid)
                        self.appState.enterFreeMove()
                        // Don't show grid overlay in free move only mode
                    }
                }
                return nil  // Consume the event
            }
        }
        
        // If not active, pass through all events
        guard appState.isActiveNonisolated else {
            return Unmanaged.passRetained(event)
        }
        
        // We're in active mode - handle input
        if type == .keyDown {
            return handleActiveKeyDown(keyCode: keyCode, flags: flags, event: event)
        }
        
        // Consume all key events while active (prevent pass-through)
        return nil
    }
    
    private func handleActiveKeyDown(keyCode: CGKeyCode, flags: CGEventFlags, event: CGEvent) -> Unmanaged<CGEvent>? {
        
        // Key code constants
        let kVKEscape: CGKeyCode = 53
        let kVKReturn: CGKeyCode = 36
        let kVKDelete: CGKeyCode = 51
        
        // Escape - deactivate
        if keyCode == kVKEscape {
            Task { @MainActor in
                self.appState.deactivate()
                self.onGridDeactivated?()
            }
            return nil
        }
        
        // Right-click shortcut (Shift + Return) - check before plain Return
        if keyCode == kVKReturn && flags.contains(.maskShift) {
            mouseController.rightClick()
            Task { @MainActor in
                self.appState.deactivate()
                self.onGridDeactivated?()
            }
            return nil
        }
        
        // Double-click shortcut (Control + Return) - check before plain Return
        if keyCode == kVKReturn && flags.contains(.maskControl) {
            mouseController.doubleClick()
            Task { @MainActor in
                self.appState.deactivate()
                self.onGridDeactivated?()
            }
            return nil
        }
        
        // Return/Enter - perform left click
        if keyCode == kVKReturn {
            mouseController.leftClick()
            Task { @MainActor in
                self.appState.deactivate()
                self.onGridDeactivated?()
            }
            return nil
        }
        
        // Additional key codes
        let kVKTab: CGKeyCode = 48
        let kVKUpArrow: CGKeyCode = 126
        let kVKDownArrow: CGKeyCode = 125
        let kVKLeftArrow: CGKeyCode = 123
        let kVKRightArrow: CGKeyCode = 124
        
        // Tab - toggle between grid and free move mode (only if both are enabled)
        if keyCode == kVKTab {
            Task { @MainActor in
                let gridEnabled = self.appState.isGridModeEnabled
                let freeMoveEnabled = self.appState.isFreeMoveEnabled
                
                // Only toggle if both modes are enabled
                if gridEnabled && freeMoveEnabled {
                    self.appState.toggleFreeMove()
                    // Hide grid overlay in free move, show in grid mode
                    if self.appState.currentMode == .freeMove {
                        self.onGridDeactivated?()
                    } else {
                        self.onGridActivated?()
                    }
                }
            }
            return nil
        }
        
        // Middle-click with Control + Return
        if keyCode == kVKReturn && flags.contains(.maskControl) {
            mouseController.middleClick()
            Task { @MainActor in
                self.appState.deactivate()
                self.onGridDeactivated?()
            }
            return nil
        }
        
        // D key - toggle drag mode
        let kVKD: CGKeyCode = 2
        if keyCode == kVKD {
            Task { @MainActor in
                if self.appState.isDragging {
                    // Stop dragging - release mouse button
                    self.mouseController.releaseDrag()
                    self.appState.stopDrag()
                } else {
                    // Start dragging - press mouse button down
                    self.mouseController.startDrag()
                    self.appState.startDrag()
                }
            }
            return nil
        }
        
        // Check for scroll mode (Command + arrow keys)
        if flags.contains(.maskCommand) {
            if let direction = getMovementDirection(keyCode: keyCode) {
                handleScroll(direction: direction, flags: flags)
                return nil
            }
        }
        
        // Handle arrow keys and HJKL for free move (work in any active mode)
        if let direction = getMovementDirection(keyCode: keyCode) {
            handleMovement(direction: direction, flags: flags)
            return nil
        }
        
        // Handle letter input for grid navigation (only in grid/refinement modes)
        if let char = keyCodeToCharacter(keyCode) {
            handleGridInput(char)
            return nil
        }
        
        // Backspace - clear first letter or exit refinement mode
        if keyCode == kVKDelete {
            Task { @MainActor in
                if self.appState.firstGridLetter != nil {
                    // Clear the typed first letter
                    self.appState.clearFirstGridLetter()
                } else if self.appState.isInRefinementMode {
                    // Exit refinement, go back to full grid
                    self.appState.backToFullGrid()
                    self.singleLetterGrid = nil
                    self.onGridActivated?()  // Trigger overlay to show full grid again
                }
            }
            return nil
        }
        
        // Consume unknown keys to prevent pass-through
        return nil
    }
    
    /// Convert key code to uppercase character (A-Z only)
    private func keyCodeToCharacter(_ keyCode: CGKeyCode) -> Character? {
        let keyCodeMap: [CGKeyCode: Character] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
            38: "J", 40: "K", 45: "N", 46: "M"
        ]
        return keyCodeMap[keyCode]
    }
    
    private func handleGridInput(_ char: Character) {
        Task { @MainActor in
            // Check if we're in refinement mode - single letter input
            if appState.isInRefinementMode, let grid = singleLetterGrid {
                // Single letter navigation in sub-grid
                if let position = grid.positionFor(letter: char) {
                    mouseController.moveCursor(to: position)
                    appState.updateCursorPosition(position)
                    onCursorMoved?(position)
                    print("[NoMouse] Refined to \(char) at \(position)")
                }
                // Stay in refinement mode for further adjustments
                return
            }
            
            // Full grid mode - needs two letters
            if let firstLetter = appState.firstGridLetter {
                // We have the first letter, this is the second
                let label = String([firstLetter, char])
                
                if let cellBounds = gridCalculator.frameFor(label: label),
                   let position = gridCalculator.positionFor(label: label) {
                    // Move cursor to the cell center
                    mouseController.moveCursor(to: position)
                    appState.updateCursorPosition(position)
                    onCursorMoved?(position)
                    
                    // Create single-letter grid for this cell
                    singleLetterGrid = SingleLetterGrid(bounds: cellBounds)
                    
                    // Enter refinement mode
                    appState.enterRefinementMode(cell: label, bounds: cellBounds)
                    onRefinementEntered?(cellBounds)
                    
                    print("[NoMouse] Jumped to \(label), entering single-letter refinement")
                }
            } else {
                // This is the first letter
                appState.setFirstGridLetter(char)
            }
        }
    }
    
    // MARK: - Movement Direction
    
    enum MovementDirection {
        case up, down, left, right
    }
    
    /// Map key codes to movement directions (arrows + HJKL vim-style)
    private func getMovementDirection(keyCode: CGKeyCode) -> MovementDirection? {
        switch keyCode {
        case 126: return .up      // Up arrow
        case 125: return .down    // Down arrow
        case 123: return .left    // Left arrow
        case 124: return .right   // Right arrow
        default:  return nil
        }
    }
    
    /// Handle movement in specified direction with speed modifiers and acceleration
    private func handleMovement(direction: MovementDirection, flags: CGEventFlags) {
        let now = Date()
        let timeSinceLastMove = now.timeIntervalSince(lastMoveTime)
        
        // Check if this is a continuation (same direction, within timeout)
        if direction == lastMoveDirection && timeSinceLastMove < accelerationTimeout {
            // Accelerate!
            currentAcceleration = min(currentAcceleration + accelerationIncrement, maxAcceleration)
        } else {
            // Reset acceleration (new direction or too much time passed)
            currentAcceleration = 1.0
        }
        
        // Update tracking
        lastMoveTime = now
        lastMoveDirection = direction
        
        Task { @MainActor in
            // Calculate movement amount based on modifiers and acceleration
            var speed = appState.movementSpeed * currentAcceleration
            
            if flags.contains(.maskShift) {
                // Fast movement
                speed *= appState.fastMultiplier
            } else if flags.contains(.maskAlternate) {
                // Slow/precise movement (also resets acceleration for fine control)
                speed = appState.movementSpeed / appState.slowDivisor
            }
            
            // Get current position
            let currentPos = NSEvent.mouseLocation
            // Convert from screen coordinates (origin bottom-left) to CG coordinates (origin top-left)
            let screenHeight = NSScreen.main?.frame.height ?? 0
            var newX = currentPos.x
            var newY = screenHeight - currentPos.y
            
            // Apply movement
            switch direction {
            case .up:    newY -= speed
            case .down:  newY += speed
            case .left:  newX -= speed
            case .right: newX += speed
            }
            
            // Multi-monitor: Get bounds of all screens
            let allScreenBounds = NSScreen.screens.reduce(CGRect.zero) { result, screen in
                result.union(screen.frame)
            }
            
            // Clamp to combined screen bounds
            newX = max(allScreenBounds.minX, min(allScreenBounds.maxX - 1, newX))
            newY = max(0, min(allScreenBounds.height - 1, newY))
            
            let newPosition = CGPoint(x: newX, y: newY)
            
            // Use drag move if in drag mode, otherwise normal move
            if appState.isDragging {
                mouseController.dragMove(to: newPosition)
            } else {
                mouseController.moveCursor(to: newPosition)
            }
            appState.updateCursorPosition(newPosition)
        }
    }
    
    /// Handle scroll in specified direction
    private func handleScroll(direction: MovementDirection, flags: CGEventFlags) {
        Task { @MainActor in
            var scrollAmount = appState.scrollSpeed
            
            // Shift for faster scroll
            if flags.contains(.maskShift) {
                scrollAmount *= 3
            }
            
            switch direction {
            case .up:
                mouseController.scroll(deltaY: scrollAmount)
            case .down:
                mouseController.scroll(deltaY: -scrollAmount)
            case .left:
                mouseController.scrollHorizontal(deltaX: -scrollAmount)
            case .right:
                mouseController.scrollHorizontal(deltaX: scrollAmount)
            }
        }
    }
    
    /// Reset acceleration (call on key up or mode change)
    private func resetAcceleration() {
        currentAcceleration = 1.0
        lastMoveDirection = nil
    }
}

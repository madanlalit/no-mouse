import Foundation
import CoreGraphics
import AppKit

/// Controls mouse cursor movement and synthetic mouse events
/// Security Note: Only generates mouse events, never captures or logs any data
final class MouseController {
    
    // MARK: - Mouse Movement
    
    /// Move cursor to absolute screen position
    /// - Parameter point: Target position in screen coordinates
    /// - Returns: True if successful
    @discardableResult
    func moveCursor(to point: CGPoint) -> Bool {
        // CGWarpMouseCursorPosition moves the cursor instantly
        let result = CGWarpMouseCursorPosition(point)
        if result == .success {
            // Disable mouse acceleration briefly to prevent drift
            CGAssociateMouseAndMouseCursorPosition(1)
            return true
        }
        print("[NoMouse] Failed to move cursor: \(result)")
        return false
    }
    
    // MARK: - Click Actions
    
    /// Perform a left click at current cursor position
    func leftClick(at point: CGPoint? = nil) {
        let position = point ?? currentCursorPosition
        postMouseEvent(type: .leftMouseDown, at: position, button: .left)
        postMouseEvent(type: .leftMouseUp, at: position, button: .left)
    }
    
    /// Perform a right click at current cursor position
    func rightClick(at point: CGPoint? = nil) {
        let position = point ?? currentCursorPosition
        postMouseEvent(type: .rightMouseDown, at: position, button: .right)
        postMouseEvent(type: .rightMouseUp, at: position, button: .right)
    }
    
    /// Perform a double left click
    func doubleClick(at point: CGPoint? = nil) {
        let position = point ?? currentCursorPosition
        
        // First click
        postMouseEvent(type: .leftMouseDown, at: position, button: .left, clickCount: 1)
        postMouseEvent(type: .leftMouseUp, at: position, button: .left, clickCount: 1)
        
        // Second click (with clickCount = 2)
        postMouseEvent(type: .leftMouseDown, at: position, button: .left, clickCount: 2)
        postMouseEvent(type: .leftMouseUp, at: position, button: .left, clickCount: 2)
    }
    
    /// Perform a middle click
    func middleClick(at point: CGPoint? = nil) {
        let position = point ?? currentCursorPosition
        postMouseEvent(type: .otherMouseDown, at: position, button: .center)
        postMouseEvent(type: .otherMouseUp, at: position, button: .center)
    }
    
    // MARK: - Drag Operations
    
    /// Start a drag operation (mouse button down without release)
    func startDrag(at point: CGPoint? = nil) {
        let position = point ?? currentCursorPosition
        postMouseEvent(type: .leftMouseDown, at: position, button: .left)
    }
    
    /// Release a drag operation (mouse button up)
    func releaseDrag(at point: CGPoint? = nil) {
        let position = point ?? currentCursorPosition
        postMouseEvent(type: .leftMouseUp, at: position, button: .left)
    }
    
    /// Move while dragging (sends drag event, not just move)
    func dragMove(to point: CGPoint) {
        guard let event = CGEvent(mouseEventSource: nil,
                                   mouseType: .leftMouseDragged,
                                   mouseCursorPosition: point,
                                   mouseButton: .left) else {
            print("[NoMouse] Failed to create drag event")
            return
        }
        event.post(tap: .cghidEventTap)
    }
    
    // MARK: - Scroll
    
    /// Scroll vertically
    /// - Parameter delta: Positive = up, Negative = down
    func scroll(deltaY: Int32) {
        guard let event = CGEvent(scrollWheelEvent2Source: nil,
                                   units: .pixel,
                                   wheelCount: 1,
                                   wheel1: deltaY,
                                   wheel2: 0,
                                   wheel3: 0) else {
            print("[NoMouse] Failed to create scroll event")
            return
        }
        event.post(tap: .cghidEventTap)
    }
    
    /// Scroll horizontally
    /// - Parameter delta: Positive = right, Negative = left
    func scrollHorizontal(deltaX: Int32) {
        guard let event = CGEvent(scrollWheelEvent2Source: nil,
                                   units: .pixel,
                                   wheelCount: 2,
                                   wheel1: 0,
                                   wheel2: deltaX,
                                   wheel3: 0) else {
            print("[NoMouse] Failed to create horizontal scroll event")
            return
        }
        event.post(tap: .cghidEventTap)
    }
    
    // MARK: - Utilities
    
    /// Get current cursor position
    var currentCursorPosition: CGPoint {
        NSEvent.mouseLocation.flipped
    }
    
    /// Get main screen bounds
    var screenBounds: CGRect {
        NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
    }
    
    // MARK: - Private Methods
    
    private func postMouseEvent(type: CGEventType,
                                 at point: CGPoint,
                                 button: CGMouseButton,
                                 clickCount: Int64 = 1) {
        guard let event = CGEvent(mouseEventSource: nil,
                                   mouseType: type,
                                   mouseCursorPosition: point,
                                   mouseButton: button) else {
            print("[NoMouse] Failed to create mouse event: \(type)")
            return
        }
        
        // Set click count for double-clicks
        event.setIntegerValueField(.mouseEventClickState, value: clickCount)
        
        // Post to the HID event tap
        event.post(tap: .cghidEventTap)
    }
}

// MARK: - Coordinate Helpers

extension NSPoint {
    /// Convert from AppKit coordinates (origin bottom-left) to CG coordinates (origin top-left)
    var flipped: CGPoint {
        guard let screenHeight = NSScreen.main?.frame.height else {
            return CGPoint(x: x, y: y)
        }
        return CGPoint(x: x, y: screenHeight - y)
    }
}

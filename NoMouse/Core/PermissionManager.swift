import Foundation
import AppKit
import ApplicationServices

/// Manages macOS Accessibility and Input Monitoring permissions
/// Security Note: Only checks permission status, never stores or transmits any data
@MainActor
final class PermissionManager: ObservableObject {
    
    @Published private(set) var hasAccessibilityPermission: Bool = false
    @Published private(set) var hasInputMonitoringPermission: Bool = false
    
    var hasAllPermissions: Bool {
        hasAccessibilityPermission && hasInputMonitoringPermission
    }
    
    private var permissionCheckTimer: Timer?
    
    init() {
        checkPermissions()
        startMonitoringPermissions()
    }
    
    deinit {
        permissionCheckTimer?.invalidate()
    }
    
    /// Check current permission status
    func checkPermissions() {
        hasAccessibilityPermission = AXIsProcessTrusted()
        hasInputMonitoringPermission = checkInputMonitoringPermission()
    }
    
    /// Request Accessibility permission - opens System Settings
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // After requesting, check again after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkPermissions()
        }
    }
    
    /// Request Input Monitoring permission
    func requestInputMonitoringPermission() {
        // CGRequestListenEventAccess prompts the user
        let granted = CGRequestListenEventAccess()
        if granted {
            hasInputMonitoringPermission = true
        }
    }
    
    /// Open System Settings to the appropriate pane
    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func openInputMonitoringSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Private Methods
    
    private func checkInputMonitoringPermission() -> Bool {
        // CGPreflightListenEventAccess checks without prompting
        return CGPreflightListenEventAccess()
    }
    
    private func startMonitoringPermissions() {
        // Poll for permission changes every 2 seconds
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermissions()
            }
        }
    }
}

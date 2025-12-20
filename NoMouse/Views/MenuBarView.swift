import SwiftUI

/// Menu bar dropdown view
struct MenuBarView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var permissionManager: PermissionManager
    
    var onQuit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status Header
            statusSection
            
            Divider()
            
            // Permissions Section (if needed)
            if !permissionManager.hasAllPermissions {
                permissionsSection
                Divider()
            }
            
            // Controls
            controlsSection
            
            Divider()
            
            // Info
            infoSection
            
            Divider()
            
            // Quit
            Button("Quit NoMouse") {
                onQuit()
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 260)
    }
    
    // MARK: - Sections
    
    private var statusSection: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(appState.statusText)
                .font(.system(.body, design: .monospaced))
            
            Spacer()
        }
    }
    
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Permissions Required")
                .font(.headline)
                .foregroundColor(.orange)
            
            // Accessibility
            HStack {
                Image(systemName: permissionManager.hasAccessibilityPermission ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(permissionManager.hasAccessibilityPermission ? .green : .red)
                
                Text("Accessibility")
                
                Spacer()
                
                if !permissionManager.hasAccessibilityPermission {
                    Button("Grant") {
                        permissionManager.requestAccessibilityPermission()
                    }
                    .buttonStyle(.link)
                }
            }
            .font(.system(.caption, design: .monospaced))
            
            // Input Monitoring
            HStack {
                Image(systemName: permissionManager.hasInputMonitoringPermission ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(permissionManager.hasInputMonitoringPermission ? .green : .red)
                
                Text("Input Monitoring")
                
                Spacer()
                
                if !permissionManager.hasInputMonitoringPermission {
                    Button("Grant") {
                        permissionManager.requestInputMonitoringPermission()
                    }
                    .buttonStyle(.link)
                }
            }
            .font(.system(.caption, design: .monospaced))
        }
    }
    
    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Enabled", isOn: $appState.isEnabled)
                .toggleStyle(.switch)
        }
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Shortcuts")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Group {
                Text("⌃ Space → Activate grid")
                Text("Type 2 letters → Jump cursor")
                Text("Return → Left click")
                Text("⇧ Return → Right click")
                Text("Escape → Cancel")
            }
            .font(.system(.caption2, design: .monospaced))
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        guard permissionManager.hasAllPermissions else { return .orange }
        guard appState.isEnabled else { return .gray }
        
        switch appState.currentMode {
        case .idle:
            return .green
        case .gridActive:
            return .cyan
        case .gridRefinement:
            return .mint
        case .freeMove:
            return .blue
        }
    }
}

import SwiftUI

/// Menu bar dropdown view
struct MenuBarView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var permissionManager: PermissionManager
    @Environment(\.dismiss) private var dismiss
    
    var onQuit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
        .padding(10)
        .frame(width: 220)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Enabled")
                Spacer()
                Toggle("", isOn: $appState.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            
            if appState.isEnabled {
                Divider()
                    .padding(.vertical, 2)
                
                Text("Modes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Grid Mode")
                    Spacer()
                    Toggle("", isOn: $appState.isGridModeEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .help("Show letter grid overlay for quick cursor positioning")
                }
                
                HStack {
                    Text("Flow Mode")
                    Spacer()
                    Toggle("", isOn: $appState.isFreeMoveEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .help("Move cursor with arrow keys or HJKL")
                }
            }
        }
    }
    
    private var infoSection: some View {
        Button(action: {
            if let url = URL(string: "https://github.com/madanlalit/no-mouse/blob/main/SHORTCUTS.md") {
                NSWorkspace.shared.open(url)
            }
            dismiss()
        }) {
            HStack {
                Image(systemName: "keyboard")
                Text("View Shortcuts")
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
            }
            .font(.system(.body, design: .monospaced))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
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

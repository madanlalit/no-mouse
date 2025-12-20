import SwiftUI
import AppKit
import Combine

/// NoMouse - Keyboard-driven mouse control for macOS
/// A menu bar application that enables mouse control using only the keyboard
@main
struct NoMouseApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Label("NoMouse", systemImage: "cursorarrow")
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Content View (Holds the state)

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var permissionManager = PermissionManager()
    @StateObject private var overlayController = OverlayWindowController()
    @StateObject private var appController = AppController()
    
    var body: some View {
        MenuBarView(
            appState: appState,
            permissionManager: permissionManager,
            onQuit: { NSApplication.shared.terminate(nil) }
        )
        .onAppear {
            appController.setup(
                appState: appState,
                permissionManager: permissionManager,
                overlayController: overlayController
            )
        }
    }
}

// MARK: - App Controller (Manages event tap lifecycle)

@MainActor
final class AppController: ObservableObject {
    private let mouseController = MouseController()
    private var keyboardController: KeyboardEventController?
    private var cancellables = Set<AnyCancellable>()
    
    func setup(appState: AppState, permissionManager: PermissionManager, overlayController: OverlayWindowController) {
        // Start immediately if permissions are already granted
        if permissionManager.hasAllPermissions {
            startEventTap(appState: appState, overlayController: overlayController)
        }
        
        // Watch for permission changes
        Publishers.CombineLatest(
            permissionManager.$hasAccessibilityPermission,
            permissionManager.$hasInputMonitoringPermission
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] accessibility, inputMonitoring in
            if accessibility && inputMonitoring {
                self?.startEventTap(appState: appState, overlayController: overlayController)
            }
        }
        .store(in: &cancellables)
    }
    
    private func startEventTap(appState: AppState, overlayController: OverlayWindowController) {
        guard keyboardController == nil else { return }
        
        let controller = KeyboardEventController(
            appState: appState,
            mouseController: mouseController
        )
        
        // Wire up callbacks
        controller.onGridActivated = {
            Task { @MainActor in
                overlayController.show()
            }
        }
        
        controller.onGridDeactivated = {
            Task { @MainActor in
                overlayController.hide()
            }
        }
        
        controller.onRefinementEntered = { cellBounds in
            Task { @MainActor in
                overlayController.enterRefinement(cellBounds: cellBounds)
            }
        }
        
        controller.onCursorMoved = { _ in
            // Could add visual feedback here
        }
        
        // Start the event tap
        if controller.start() {
            keyboardController = controller
            print("[NoMouse] Event tap initialized successfully")
        } else {
            print("[NoMouse] Failed to start event tap")
        }
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure we don't show in the Dock
        NSApp.setActivationPolicy(.accessory)
    }
}

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private let petCollectionViewModel = PetCollectionViewModel()
    private lazy var taskListViewModel = TaskListViewModel(store: UserDefaultsTaskStore(), petCollectionViewModel: petCollectionViewModel)
    private var escMonitor: Any?
    private static let hotKeyKeyCode: UInt16 = 42 // kVK_ANSI_Backslash

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["com.poketasks.soundEffectsEnabled": true])

        if let button = statusItem.button {
            button.image = SpriteImageLoader.shared.loadMenuBarIcon()
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: PopoverPagerView(taskListViewModel: taskListViewModel, petCollectionViewModel: petCollectionViewModel)
        )

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handlePotentialHotKey(event)
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handlePotentialHotKey(event)
            return event
        }
    }

    private func handlePotentialHotKey(_ event: NSEvent) {
        guard event.keyCode == Self.hotKeyKeyCode,
              event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command, .shift],
              let button = statusItem.button else { return }
        togglePopover(relativeTo: button)
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showQuitMenu(relativeTo: sender)
        } else {
            togglePopover(relativeTo: sender)
        }
    }

    private func togglePopover(relativeTo button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func showQuitMenu(relativeTo button: NSStatusBarButton) {
        let menu = NSMenu()

        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(launchAtLoginItem)

        let soundEffectsItem = NSMenuItem(
            title: "Sound Effects",
            action: #selector(toggleSoundEffects),
            keyEquivalent: ""
        )
        soundEffectsItem.target = self
        soundEffectsItem.state = SoundEffects.isEnabled ? .on : .off
        menu.addItem(soundEffectsItem)
        menu.addItem(.separator())

        menu.addItem(withTitle: "Quit PokeTasks", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLogin.setEnabled(!LaunchAtLogin.isEnabled)
    }

    @objc private func toggleSoundEffects() {
        SoundEffects.setEnabled(!SoundEffects.isEnabled)
    }

    func popoverWillShow(_ notification: Notification) {
        taskListViewModel.pruneExpiredTasks()
        petCollectionViewModel.checkFriendshipDecay()

        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 { // Escape
                self.popover.performClose(nil)
                return nil
            }
            return event
        }
    }

    func popoverDidClose(_ notification: Notification) {
        if let escMonitor {
            NSEvent.removeMonitor(escMonitor)
            self.escMonitor = nil
        }
    }
}

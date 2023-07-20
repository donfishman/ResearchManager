import SwiftUI
import AppKit

@main
struct research_managerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var window: NSWindow?
    var mainWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 创建状态栏图标
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusBarItem.button {
            button.image = NSImage(named: "StatusBarIcon")  // 使用你的图标文件名替换 "StatusBarIcon"
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // 获取 SwiftUI 创建的窗口
        window = NSApplication.shared.windows.first
        mainWindowController = NSWindowController(window: window)

        NSApp.activate(ignoringOtherApps: true) // 激活应用程序，确保它处于前台
        mainWindowController?.showWindow(nil) // 显示新窗口
        window?.makeKeyAndOrderFront(nil) // 将新窗口置于最前
    }

    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        switch event.type {
        case .rightMouseUp:
            // 如果是右键单击，就显示右键菜单
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "设置", action: #selector(openSettings(_:)), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "退出", action: #selector(quit(_:)), keyEquivalent: ""))

            statusBarItem.menu = menu
            statusBarItem.button?.performClick(nil)
            statusBarItem.menu = nil
        default:
            // 默认情况下，切换窗口
            NSApp.activate(ignoringOtherApps: true)
            mainWindowController?.showWindow(nil)
        }
    }

    @objc func openSettings(_ sender: Any?) {
        // 在这里添加打开设置窗口的代码
    }

    @objc func quit(_ sender: Any?) {
        NSApplication.shared.terminate(self)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // 如果窗口不可见（例如被隐藏），则激活并打开窗口
            NSApp.activate(ignoringOtherApps: true)
            mainWindowController?.showWindow(nil)
        }
        return true
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        // Don't create a new window when the application becomes active or reopens
        return false
    }
}

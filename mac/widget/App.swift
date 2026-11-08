// wake-and-stream – the widget app ("Wake and Stream.app").
// Runs invisibly in the background (no Dock icon, starts at login) and does what the menu bar plugin did:
//   • every 10 s: "pc state" → ~/.config/wake-and-stream/widget-state → widget is redrawn when something changed
//   • widget click:
//       wakeandstream://ask/<action>  → the widget asks "really …?" itself (cancels itself after 20 s)
//       wakeandstream://do/<action>   → ~/.config/wake-and-stream/action.sh <action> without dialog
//       wakeandstream://cancel        → back to normal
//       wakeandstream://<action>      → action.sh with the dialogs of the menu bar
//     (notifications like the menu bar)
import AppKit
import notify
import ServiceManagement
import WidgetKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var timer: Timer?
    private var stateText = ""        // last output of "pc state"
    private var busy = ""             // action running right now
    private var confirm = ""          // action waiting for "really …?" in the widget
    private var confirmToken = 0
    private var lastShown = ""        // what the widget currently shows (to redraw only on changes)
    private var polling = false
    private let pollQueue = DispatchQueue(label: "wake-and-stream.poll")
    private let actionQueue = DispatchQueue(label: "wake-and-stream.action")

    static let actions: Set<String> = ["on", "work", "play", "stop", "release", "off", "sleep"]

    func applicationDidFinishLaunching(_ notification: Notification) {
        // start automatically at login (shows up in System Settings → General → Login Items)
        if SMAppService.mainApp.status != .enabled { try? SMAppService.mainApp.register() }
        // widget button clicked → system notification → read the request file
        var token: Int32 = 0
        notify_register_dispatch(WidgetRequest.notification, &token, .main) { [weak self] _ in self?.takeRequest() }
        takeRequest()
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.takeRequest()
            self?.poll()
        }
    }

    private func takeRequest() {
        if let r = WidgetRequest.take() { request(r) }
    }

    // Links wakeandstream://<request> (VPN, start app, and older widget versions)
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == WAS.scheme {
            request(([url.host ?? ""] + url.pathComponents.dropFirst()).joined(separator: "/"))
        }
    }

    /// "ask/<action>", "do/<action>", "cancel", "<action>", "vpn", "refresh"
    private func request(_ r: String) {
        let parts = r.split(separator: "/").map(String.init)
        let host = parts.first ?? ""
        let arg = parts.count > 1 ? parts[1] : ""
        switch host {
        case "ask" where Self.actions.contains(arg):
            confirm = arg
            confirmToken += 1
            let token = confirmToken
            publish()
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                if self.confirmToken == token && !self.confirm.isEmpty { self.confirm = ""; self.publish() }
            }
        case "do" where Self.actions.contains(arg):
            confirm = ""
            handle(arg, confirmed: true)
        case "cancel":
            confirm = ""
            publish()
        default:
            handle(host)
        }
    }

    private func handle(_ action: String, confirmed: Bool = false) {
        switch action {
        case "vpn":
            run("/usr/bin/open", ["-a", "WireGuard"])
        case "refresh":
            poll()
        case _ where Self.actions.contains(action):
            guard busy.isEmpty else { return }       // one action at a time
            busy = action
            publish()
            actionQueue.async {
                self.run("/bin/bash", [WAS.dir + "/action.sh", action], confirmed: confirmed)
                DispatchQueue.main.async {
                    self.busy = ""
                    self.poll()
                }
            }
        default:
            break
        }
    }

    private func poll() {
        guard !polling else { return }
        polling = true
        pollQueue.async {
            let out = self.run("/bin/bash", [self.pcCommand, "state"])
            DispatchQueue.main.async {
                self.polling = false
                if out.contains("home=") { self.stateText = out }
                self.publish()
            }
        }
    }

    /// Write the state file for the widget; redraw the widget only if something changed.
    private func publish() {
        let content = stateText + "busy=\(busy)\nconfirm=\(confirm)\n"
        let file = content + "time=\(Int(Date().timeIntervalSince1970))\n"
        try? file.write(toFile: WAS.stateFile, atomically: true, encoding: .utf8)
        // also redraw once a minute, so the widget does not think the app has stopped
        let minute = Int(Date().timeIntervalSince1970 / 60)
        let key = content + "\(minute)"
        if key != lastShown {
            lastShown = key
            WidgetCenter.shared.reloadTimelines(ofKind: WAS.widgetKind)
        }
    }

    /// The pc command (installed by install.sh)
    private var pcCommand: String {
        for p in ["/usr/local/bin/pc", "/opt/homebrew/bin/pc"] where FileManager.default.fileExists(atPath: p) { return p }
        return "/usr/local/bin/pc"
    }

    @discardableResult
    private func run(_ tool: String, _ args: [String], confirmed: Bool = false) -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: tool)
        p.arguments = args
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        if confirmed { env["WAS_CONFIRMED"] = "1" }   // already confirmed in the widget → no dialog
        env["WAS_QUIET"] = "1"   // the widget shows the state itself → notifications only for errors
        p.environment = env
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }
}

@main
enum Main {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)   // no Dock icon, no menu bar
        app.run()
    }
}

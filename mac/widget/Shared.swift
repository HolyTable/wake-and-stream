// wake-and-stream – shared by the widget app and the widget extension.
// The app writes the PC state to ~/.config/wake-and-stream/widget-state (key=value lines),
// the widget only reads it (the widget runs in a sandbox and cannot check the network itself).
import Foundation
import notify

enum WAS {
    /// The real home folder (inside the sandbox NSHomeDirectory() points to the container).
    static var home: String {
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir { return String(cString: dir) }
        return NSHomeDirectory()
    }
    static var dir: String { home + "/.config/wake-and-stream" }
    static var stateFile: String { dir + "/widget-state" }
    static let scheme = "wakeandstream"
    static let widgetKind = "WakeAndStream"
    /// preview.swift: draw buttons without Link (the image renderer cannot draw links)
    nonisolated(unsafe) static var preview = false
}

/// Widget → app: the widget writes the clicked action ("ask/on", "do/off", "cancel" …) to a file
/// and posts a system notification; the app reacts at once.
enum WidgetRequest {
    static var file: String { WAS.dir + "/widget-request" }
    static let notification = "io.github.holytable.wake-and-stream.request"

    static func send(_ action: String) {
        try? (action + "\n").write(toFile: file, atomically: true, encoding: .utf8)
        notify_post(notification)
    }

    /// Read and remove the pending request (app side)
    static func take() -> String? {
        guard let text = try? String(contentsOfFile: file, encoding: .utf8) else { return nil }
        try? FileManager.default.removeItem(atPath: file)
        let a = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return a.isEmpty ? nil : a
    }
}

/// What the PC is doing right now – parsed from "pc state" plus what the app adds (busy, time).
struct PCState {
    var home = false          // home network reachable (VPN up)
    var on = false            // PC on
    var stream = 0            // 2 = Moonlight open, 1 = paused, 0 = none
    var rdp = false           // remote desktop connected from this Mac
    var last = ""             // "sleep"/"off" while the PC is off
    var lang = "en"
    var busy = ""             // action that is running right now (on/work/play/stop/release/off/sleep)
    var confirm = ""          // action waiting for "really …?" in the widget
    var time = Date.distantPast

    init() {}

    init(text: String) {
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count >= 1 else { continue }
            let key = parts[0], value = parts.count > 1 ? parts[1] : ""
            switch key {
            case "home":   home = value == "1"
            case "on":     on = value == "1"
            case "stream": stream = Int(value) ?? 0
            case "rdp":    rdp = value == "1"
            case "last":   last = value
            case "lang":   lang = value
            case "busy":   busy = value
            case "confirm": confirm = value
            case "time":   time = Date(timeIntervalSince1970: Double(value) ?? 0)
            default: break
            }
        }
    }

    static func load() -> PCState? {
        guard let text = try? String(contentsOfFile: WAS.stateFile, encoding: .utf8) else { return nil }
        return PCState(text: text)
    }

    func t(_ key: String) -> String { Texts.get(key, lang) }
}

/// Texts in German and English (like t() in lib.sh).
enum Texts {
    static func get(_ key: String, _ lang: String) -> String {
        let de = lang == "de"
        switch key {
        case "title":         return "PC"
        case "s_on":          return de ? "An" : "On"
        case "s_off":         return de ? "Aus" : "Off"
        case "s_sleep":       return de ? "Schläft" : "Asleep"
        case "s_nohome":      return de ? "Heimnetz nicht erreichbar" : "Home network not reachable"
        case "s_noapp":       return de ? "Widget-App läuft nicht" : "Widget app is not running"
        case "s_rdp":         return de ? "Remotedesktop läuft" : "Remote desktop on"
        case "s_stream":      return de ? "Stream läuft" : "Streaming"
        case "s_paused":      return de ? "Stream pausiert" : "Stream paused"
        case "busy_on":       return de ? "Wird eingeschaltet …" : "Turning on …"
        case "busy_work":     return de ? "Remotedesktop startet …" : "Starting remote desktop …"
        case "busy_play":     return de ? "Stream startet …" : "Starting stream …"
        case "busy_then_work": return de ? "Danach Remotedesktop" : "Then remote desktop"
        case "busy_then_play": return de ? "Danach Stream" : "Then stream"
        case "busy_stop":     return de ? "Stream wird beendet …" : "Ending stream …"
        case "busy_release":  return de ? "Remotedesktop wird beendet …" : "Ending remote desktop …"
        case "busy_off":      return de ? "Fährt herunter …" : "Shutting down …"
        case "busy_sleep":    return de ? "Wird schlafen gelegt …" : "Going to sleep …"
        case "a_on":          return de ? "Einschalten" : "Turn on"
        case "a_wake":        return de ? "Aufwecken" : "Wake up"
        case "a_work":        return de ? "Arbeiten" : "Work"
        case "a_work_end":    return de ? "Arbeiten beenden" : "End work"
        case "a_play":        return de ? "Spielen" : "Play"
        case "a_resume":      return de ? "Weiterspielen" : "Resume"
        case "a_play_end":    return de ? "Spielen beenden" : "End play"
        case "a_off":         return de ? "Herunterfahren" : "Shut down"
        case "a_sleep":       return de ? "Standby" : "Sleep"
        case "a_vpn":         return de ? "VPN öffnen" : "Open VPN"
        case "a_start_app":   return de ? "App starten" : "Start app"
        case "q_on":          return de ? "Wirklich einschalten?" : "Really turn on?"
        case "q_wake":        return de ? "Wirklich aufwecken?" : "Really wake up?"
        case "q_work":        return de ? "Einschalten und arbeiten?" : "Turn on and work?"
        case "q_play":        return de ? "Einschalten und spielen?" : "Turn on and play?"
        case "q_off":         return de ? "Wirklich herunterfahren?" : "Really shut down?"
        case "q_off_detail":  return de ? "Ungespeichertes geht verloren" : "Unsaved work is lost"
        case "q_sleep":       return de ? "Wirklich schlafen legen?" : "Really put to sleep?"
        case "a_yes_work":    return de ? "Ja, arbeiten" : "Yes, work"
        case "a_yes_play":    return de ? "Ja, spielen" : "Yes, play"
        case "a_cancel":      return de ? "Abbrechen" : "Cancel"
        case "desc":          return de ? "PC einschalten, arbeiten, spielen und ausschalten."
                                        : "Turn your PC on, work, play and shut it down."
        default:              return key
        }
    }

    /// Language for texts shown before any state exists (gallery): from the Mac's language.
    static var systemLang: String {
        (Locale.preferredLanguages.first ?? "en").hasPrefix("de") ? "de" : "en"
    }
}

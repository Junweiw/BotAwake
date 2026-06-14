import Cocoa

// BotAwake — a menu-bar switch that keeps the Mac awake so the Lark bots stay
// reachable, while still letting the screen sleep & lock. Pure caffeinate under
// the hood. Built locally, no third-party dependencies.

enum Mode: Equatable {
    case normal          // factory behavior: Mac sleeps when idle
    case stayAwake       // -i -m -s : awake, screen can sleep & lock
    case powerOnly       // like stayAwake but only while on AC power
    case timed(Int)      // awake for N seconds, then auto-return to normal
    case screenOn        // -d -i -m -s : display stays lit too (no lock)
    case lidClosed(Int)  // pmset disablesleep — awake even with lid closed; arg = battery floor %
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var mode: Mode = .normal
    var caffeinate: Process?
    var powerTimer: Timer?
    var timedDeadline: Date?

    func applicationDidFinishLaunching(_ note: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if let button = statusItem.button {
            button.image = symbol(false)
            button.toolTip = "Bot reachability"
        }
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        statusItem.menu = menu
        // Crash recovery: if disablesleep was left on after a crash, clear it
        if isDisableSleepOn() {
            setDisableSleep(false)
        }
        reconcile()
        powerTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.reconcile()
        }
    }

    // MARK: - Icon

    func symbol(_ active: Bool) -> NSImage? {
        let name = active ? "cup.and.saucer.fill" : "cup.and.saucer"
        let img = NSImage(systemSymbolName: name, accessibilityDescription: "Bot reachability")
        img?.isTemplate = true
        return img
    }

    func isActive() -> Bool {
        if case .normal = mode { return false }
        return true
    }

    func updateIcon() {
        statusItem.button?.image = symbol(isActive())
    }

    // MARK: - Power source

    func onACPower() -> Bool {
        let p = Process()
        p.launchPath = "/usr/bin/pmset"
        p.arguments = ["-g", "batt"]
        let pipe = Pipe()
        p.standardOutput = pipe
        do { try p.run() } catch { return true }
        p.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let out = String(data: data, encoding: .utf8) ?? ""
        return out.contains("AC Power")
    }

    func batteryPercent() -> Int {
        let p = Process()
        p.launchPath = "/usr/bin/pmset"
        p.arguments = ["-g", "batt"]
        let pipe = Pipe()
        p.standardOutput = pipe
        do { try p.run() } catch { return 100 }
        p.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let out = String(data: data, encoding: .utf8) ?? ""
        // pmset output e.g. "... 75%; discharging; ..."
        guard let rng = out.range(of: #"(\d+)\s*%"#, options: .regularExpression) else { return 100 }
        let numStr = out[rng].trimmingCharacters(in: CharacterSet(charactersIn: " %"))
        return Int(numStr) ?? 100
    }

    // MARK: - Lid-closed (disablesleep) control

    @discardableResult
    func setDisableSleep(_ enable: Bool) -> Bool {
        let p = Process()
        p.launchPath = "/usr/bin/sudo"
        p.arguments = ["/usr/bin/pmset", "-a", "disablesleep", enable ? "1" : "0"]
        do {
            try p.run()
            p.waitUntilExit()
            return p.terminationStatus == 0
        } catch {
            return false
        }
    }

    func isSudoersReady() -> Bool {
        return FileManager.default.fileExists(atPath: "/etc/sudoers.d/botawake")
    }

    // One-time setup: install the NOPASSWD sudoers rule via macOS's native
    // admin dialog (Touch ID / password) — no Terminal needed. After this,
    // every lid-closed toggle runs sudo pmset without a prompt.
    @discardableResult
    func installSudoers() -> Bool {
        let install = "echo '# BotAwake: allow NOPASSWD pmset disablesleep for lid-closed mode' > /etc/sudoers.d/botawake; "
            + "echo 'Cmnd_Alias BOTAWAKE = /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0' >> /etc/sudoers.d/botawake; "
            + "echo 'ALL ALL=(ALL) NOPASSWD: BOTAWAKE' >> /etc/sudoers.d/botawake; "
            + "chmod 0440 /etc/sudoers.d/botawake"
        // Escape for an AppleScript string literal, then run with admin privileges.
        let escaped = install
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"\(escaped)\" with administrator privileges "
            + "with prompt \"BotAwake needs a one-time setup to keep your Mac awake with the lid closed.\""
        let p = Process()
        p.launchPath = "/usr/bin/osascript"
        p.arguments = ["-e", script]
        do {
            try p.run()
            p.waitUntilExit()
            // terminationStatus is non-zero if the user cancels the dialog.
            return p.terminationStatus == 0 && isSudoersReady()
        } catch {
            return false
        }
    }

    func isDisableSleepOn() -> Bool {
        let p = Process()
        p.launchPath = "/usr/bin/pmset"
        p.arguments = ["-g"]
        let pipe = Pipe()
        p.standardOutput = pipe
        do { try p.run() } catch { return false }
        p.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let out = String(data: data, encoding: .utf8) ?? ""
        return out.range(of: "disablesleep\\s+1", options: .regularExpression) != nil
    }

    func notify(_ title: String, _ body: String) {
        let p = Process()
        p.launchPath = "/usr/bin/osascript"
        let scr = "display notification \"\(body.replacingOccurrences(of: "\"", with: "\\\""))\" with title \"\(title.replacingOccurrences(of: "\"", with: "\\\""))\""
        p.arguments = ["-e", scr]
        try? p.run()
    }

    // MARK: - caffeinate control

    func stopCaffeinate() {
        if let c = caffeinate {
            c.terminationHandler = nil
            if c.isRunning { c.terminate() }
        }
        caffeinate = nil
    }

    func startCaffeinate(_ args: [String]) {
        stopCaffeinate()
        let p = Process()
        p.launchPath = "/usr/bin/caffeinate"
        p.arguments = args
        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if case .timed = self.mode {     // timer ran out on its own
                    self.setMode(.normal)
                }
            }
        }
        do { try p.run(); caffeinate = p } catch { caffeinate = nil }
    }

    // Bring the running caffeinate process in line with the desired mode + power.
    func reconcile() {
        switch mode {
        case .normal:
            stopCaffeinate()
        case .stayAwake:
            if caffeinate == nil { startCaffeinate(["-i", "-m", "-s"]) }
        case .screenOn:
            if caffeinate == nil { startCaffeinate(["-d", "-i", "-m", "-s"]) }
        case .powerOnly:
            if onACPower() {
                if caffeinate == nil { startCaffeinate(["-i", "-m", "-s"]) }
            } else {
                stopCaffeinate()
            }
        case .timed:
            if caffeinate == nil {
                let remaining = max(1, Int(timedDeadline?.timeIntervalSinceNow ?? 0))
                startCaffeinate(["-i", "-m", "-s", "-t", "\(remaining)"])
            }
        case .lidClosed(let floor):
            stopCaffeinate()
            if !isSudoersReady() {
                // First use: one native macOS admin prompt installs the rule. No Terminal.
                if !installSudoers() {
                    notify("BotAwake", "Lid-closed mode needs a one-time authorization. Cancelled — staying Normal.")
                    setMode(.normal)
                    return
                }
            }
            if !setDisableSleep(true) {
                notify("BotAwake", "Lid-closed mode: sudo command failed. Check /etc/sudoers.d/botawake.")
                setMode(.normal)
                return
            }
            if !onACPower() {
                let pct = batteryPercent()
                if pct < floor {
                    notify("BotAwake", "Battery at \(pct)%, below floor of \(floor)%. Reverting to Normal.")
                    setMode(.normal)
                    return
                }
            }
        }
        updateIcon()
    }

    func setMode(_ m: Mode) {
        // Leaving lidClosed: clear the kernel flag so Mac can sleep again
        if isLidClosed() { setDisableSleep(false) }
        mode = m
        if case .timed(let secs) = m {
            timedDeadline = Date().addingTimeInterval(TimeInterval(secs))
        } else {
            timedDeadline = nil
        }
        stopCaffeinate()   // restart cleanly under the new mode
        reconcile()
    }

    // MARK: - Actions

    @objc func chooseNormal()   { setMode(.normal) }
    @objc func chooseStay()     { setMode(.stayAwake) }
    @objc func choosePower()    { setMode(.powerOnly) }
    @objc func chooseScreen()   { setMode(.screenOn) }
    @objc func chooseTimed1()   { setMode(.timed(3600)) }
    @objc func chooseTimed4()   { setMode(.timed(4 * 3600)) }
    @objc func chooseLid10()    { setMode(.lidClosed(10)) }
    @objc func chooseLid20()    { setMode(.lidClosed(20)) }
    @objc func chooseLid30()    { setMode(.lidClosed(30)) }
    @objc func quit()           { if isLidClosed() { setDisableSleep(false) }; stopCaffeinate(); NSApp.terminate(nil) }

    // MARK: - Menu

    func mk(_ title: String, _ sel: Selector?, on: Bool, sub: String?) -> NSMenuItem {
        let it = NSMenuItem(title: title, action: sel, keyEquivalent: "")
        it.target = self
        it.state = on ? .on : .off
        if let s = sub { it.subtitle = s }
        return it
    }

    func info(_ title: String, _ sub: String) -> NSMenuItem {
        let it = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        it.isEnabled = false
        it.subtitle = sub
        return it
    }

    func statusLine() -> String {
        switch mode {
        case .normal:    return "Now: Normal — Mac sleeps when idle"
        case .stayAwake: return "Now: Stay awake — keep the lid open"
        case .powerOnly: return onACPower() ? "Now: Awake on power — active (plugged in)"
                                            : "Now: Awake on power — paused (on battery)"
        case .screenOn:  return "Now: Screen stays on — not locked"
        case .timed:
            let mins = max(0, Int((timedDeadline?.timeIntervalSinceNow ?? 0) / 60))
            return "Now: Timed — ~\(mins) min left, then Normal"
        case .lidClosed(let floor):
            let pct = batteryPercent()
            let src = onACPower() ? "plugged in" : "battery at \(pct)%"
            return "Now: Lid closed — awake, floor at \(floor)%, \(src)"
        }
    }

    func isTimed() -> Bool { if case .timed = mode { return true }; return false }
    func isLidClosed() -> Bool { if case .lidClosed = mode { return true }; return false }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(info("Bot reachability", statusLine()))
        menu.addItem(.separator())

        menu.addItem(mk("Normal (allow sleep)", #selector(chooseNormal), on: mode == .normal,
                        sub: "Bot answers only while you're using the Mac. Best battery."))
        menu.addItem(mk("Stay awake", #selector(chooseStay), on: mode == .stayAwake,
                        sub: "Screen can sleep & lock · lid must stay OPEN · drains battery."))
        menu.addItem(mk("Awake on power only", #selector(choosePower), on: mode == .powerOnly,
                        sub: "Auto-pauses on battery, resumes when plugged in. Safe default."))

        let lidItem = NSMenuItem(title: "Stay awake with lid closed", action: nil, keyEquivalent: "")
        lidItem.state = isLidClosed() ? .on : .off
        lidItem.subtitle = "Uses pmset disablesleep · lid can close · battery floor protection."
        let lidSub = NSMenu()
        let l10 = NSMenuItem(title: "Battery floor: 10%", action: #selector(chooseLid10), keyEquivalent: ""); l10.target = self
        let l20 = NSMenuItem(title: "Battery floor: 20%", action: #selector(chooseLid20), keyEquivalent: ""); l20.target = self
        let l30 = NSMenuItem(title: "Battery floor: 30%", action: #selector(chooseLid30), keyEquivalent: ""); l30.target = self
        if case .lidClosed(let f) = mode {
            l10.state = f == 10 ? .on : .off
            l20.state = f == 20 ? .on : .off
            l30.state = f == 30 ? .on : .off
        }
        lidSub.addItem(l10); lidSub.addItem(l20); lidSub.addItem(l30)
        lidItem.submenu = lidSub
        menu.addItem(lidItem)

        let timedItem = NSMenuItem(title: "Awake for a set time", action: nil, keyEquivalent: "")
        timedItem.state = isTimed() ? .on : .off
        timedItem.subtitle = "Auto-returns to Normal when the timer ends."
        let subMenu = NSMenu()
        let t1 = NSMenuItem(title: "1 hour", action: #selector(chooseTimed1), keyEquivalent: ""); t1.target = self
        let t4 = NSMenuItem(title: "4 hours", action: #selector(chooseTimed4), keyEquivalent: ""); t4.target = self
        subMenu.addItem(t1); subMenu.addItem(t4)
        timedItem.submenu = subMenu
        menu.addItem(timedItem)

        menu.addItem(mk("Keep screen on too", #selector(chooseScreen), on: mode == .screenOn,
                        sub: "Display stays lit, no lock. Demos only. Highest battery."))

        menu.addItem(.separator())
        menu.addItem(info("Reminder · the lid",
                          "Normally closing the lid = sleep. Use \"Stay awake with lid closed\" to override (works on battery too)."))
        menu.addItem(info("Reminder · privacy",
                          "Clamshell shows your unlocked desktop. Press \u{2303}\u{2318}Q to lock — bot stays reachable."))

        menu.addItem(.separator())
        let q = NSMenuItem(title: "Quit BotAwake", action: #selector(quit), keyEquivalent: "q")
        q.target = self
        menu.addItem(q)

        updateIcon()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

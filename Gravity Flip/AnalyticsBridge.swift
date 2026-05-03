// AnalyticsBridge.swift
//
// File-watcher bridge: GDScript writes one JSON event per line to
//   <Documents>/analytics_events.jsonl
// (Godot's `user://` maps to <App>/Documents on iOS.) This class reads new
// lines on a 1-second timer, forwards each to FirebaseAnalytics.logEvent,
// and truncates the file once forwarded. Truncate-after-forward means a
// crashed app might re-send a few events on relaunch — Firebase deduping
// is not a thing, but for an MVP signal-test that's an acceptable
// tradeoff vs. losing events.
//
// Events are { "name": "level_clear", "params": { "level": 3, ... } }.
// Param values are forwarded as String / NSNumber. Everything else is
// stringified.

import Foundation
import FirebaseAnalytics

@objc(AnalyticsBridge)
@objcMembers
final class AnalyticsBridge: NSObject {

    private static let queue = DispatchQueue(label: "com.jfun.gravityflip.analytics", qos: .utility)
    private static var timer: DispatchSourceTimer?
    private static let pollInterval: DispatchTimeInterval = .seconds(1)

    /// Path to the JSONL event file. Documents/analytics_events.jsonl —
    /// matches Godot's user:// mapping on iOS.
    private static var eventFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("analytics_events.jsonl")
    }

    /// Called from FirebaseBootstrap once the app finishes launching.
    @objc static func start() {
        queue.async {
            if timer != nil { return }
            let t = DispatchSource.makeTimerSource(queue: queue)
            t.schedule(deadline: .now() + pollInterval, repeating: pollInterval)
            t.setEventHandler { drainEventFile() }
            t.resume()
            timer = t
            NSLog("[AnalyticsBridge] file-watcher started at \(eventFileURL.path)")
        }
    }

    private static func drainEventFile() {
        let url = eventFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        // Read + truncate atomically: rename the file, then process the
        // copy. If we crash between rename and process, next launch picks
        // up the renamed file (handled by also draining "<file>.processing"
        // if present at start).
        let processingURL = url.appendingPathExtension("processing")
        do {
            // If a leftover .processing file exists from a prior crash,
            // process it first.
            if FileManager.default.fileExists(atPath: processingURL.path) {
                processFile(at: processingURL)
            }
            // Move the live file aside.
            try FileManager.default.moveItem(at: url, to: processingURL)
        } catch {
            // Likely the file disappeared between the existence check and
            // the move (race with GDScript appending). Try again next tick.
            return
        }
        processFile(at: processingURL)
    }

    private static func processFile(at url: URL) {
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else {
            try? FileManager.default.removeItem(at: url)
            return
        }
        var count = 0
        for line in text.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            guard let lineData = trimmed.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                NSLog("[AnalyticsBridge] skipping malformed line: \(trimmed)")
                continue
            }
            // Two record shapes:
            //   { "user_property": "<name>", "value": "<string>" }
            //   { "name": "<event>", "params": { ... } }
            if let propName = json["user_property"] as? String {
                let value = json["value"] as? String
                Analytics.setUserProperty(value, forName: propName)
            } else if let name = json["name"] as? String {
                let params = (json["params"] as? [String: Any]).map(sanitize) ?? [:]
                Analytics.logEvent(name, parameters: params)
            } else {
                continue
            }
            count += 1
        }
        try? FileManager.default.removeItem(at: url)
        if count > 0 {
            NSLog("[AnalyticsBridge] forwarded \(count) event(s)")
        }
    }

    /// Firebase accepts only NSString / NSNumber values. Coerce everything
    /// else to its description string.
    private static func sanitize(_ raw: [String: Any]) -> [String: Any] {
        var out: [String: Any] = [:]
        for (k, v) in raw {
            switch v {
            case let s as String: out[k] = s
            case let n as NSNumber: out[k] = n
            case let b as Bool: out[k] = NSNumber(value: b)
            case let i as Int: out[k] = NSNumber(value: i)
            case let d as Double: out[k] = NSNumber(value: d)
            default: out[k] = String(describing: v)
            }
        }
        return out
    }
}

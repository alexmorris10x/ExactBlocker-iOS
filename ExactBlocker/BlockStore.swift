import Foundation
import SafariServices

// Represents a parsed element hiding rule (domain##selector)
struct ElementRule: Codable, Hashable, Identifiable {
    let domain: String
    let selector: String

    var id: String { "\(domain)##\(selector)" }

    // Parse "domain.com##.selector" format
    static func parse(_ line: String) -> ElementRule? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("!") else { return nil } // skip comments

        let parts = trimmed.components(separatedBy: "##")
        guard parts.count == 2 else { return nil }

        let domain = parts[0].trimmingCharacters(in: .whitespaces)
        let selector = parts[1].trimmingCharacters(in: .whitespaces)

        guard !domain.isEmpty, !selector.isEmpty else { return nil }
        return ElementRule(domain: domain, selector: selector)
    }

    // Parse multiple lines (for importing from file)
    static func parseMultiple(_ text: String) -> [ElementRule] {
        text.components(separatedBy: .newlines).compactMap { parse($0) }
    }
}

final class BlockStore: ObservableObject {

    // A) user-saved hosts (exact URL blocking) ────────────────────────
    @Published var hosts: [String] =
        UserDefaults.standard.stringArray(forKey: "Hosts") ?? [] {
        didSet { UserDefaults.standard.set(hosts, forKey: "Hosts") }
    }

    // B) user-saved element rules (CSS hiding) ────────────────────────
    @Published var elementRules: [ElementRule] = {
        guard let data = UserDefaults.standard.data(forKey: "ElementRules"),
              let rules = try? JSONDecoder().decode([ElementRule].self, from: data)
        else { return [] }
        return rules
    }() {
        didSet {
            if let data = try? JSONEncoder().encode(elementRules) {
                UserDefaults.standard.set(data, forKey: "ElementRules")
            }
            // Also save to shared App Group for web extension
            saveRulesForWebExtension()
        }
    }

    // Shared UserDefaults for web extension access
    private let sharedDefaults = UserDefaults(suiteName: "group.com.alexmorris10x.exactblocker")

    // C) URL of blockerList.json inside the shared App-Group container
    private let rulesURL: URL = {
        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.alexmorris10x.exactblocker"
        )!
        return container.appendingPathComponent("blockerList.json")
    }()

    // D) add host helper ──────────────────────────────────────────────
    func add(host: String) {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !hosts.contains(trimmed) else { return }
        hosts.append(trimmed)
    }

    // E) add element rule helper ──────────────────────────────────────
    func add(elementRule: ElementRule) {
        guard !elementRules.contains(elementRule) else { return }
        elementRules.append(elementRule)
    }

    // F) import element rules from text ───────────────────────────────
    func importElementRules(from text: String) -> Int {
        let parsed = ElementRule.parseMultiple(text)
        var addedCount = 0
        for rule in parsed {
            if !elementRules.contains(rule) {
                elementRules.append(rule)
                addedCount += 1
            }
        }
        return addedCount
    }

    // G) save rules for web extension (in App Group) ───────────────────
    private func saveRulesForWebExtension() {
        // Convert to simple dictionary format for JavaScript
        let rulesForJS = elementRules.map { rule -> [String: String] in
            return ["domain": rule.domain, "selector": rule.selector]
        }

        if let data = try? JSONEncoder().encode(rulesForJS) {
            sharedDefaults?.set(data, forKey: "ElementRulesForExtension")
            print("📱 Saved \(rulesForJS.count) rules for web extension")
        }
    }

    // H) build rules + ask Safari to reload ───────────────────────────
    func writeRulesAndReload() {
        print("═══════════════════════════════════════════════════════════")
        print("📝 writeRulesAndReload() called")
        print("   Hosts count: \(hosts.count)")
        print("   Element rules count: \(elementRules.count)")

        // Save rules for web extension
        saveRulesForWebExtension()

        do {
            var allRules: [[String: Any]] = []

            // 1. Host blocking rules (block entire page)
            for host in hosts {
                let pattern = "^https?://(www\\.)?\(NSRegularExpression.escapedPattern(for: host))/?$"
                allRules.append([
                    "trigger": [
                        "url-filter": pattern,
                        "resource-type": ["document"]
                    ],
                    "action": ["type": "block"]
                ])
            }

            // 2. Element hiding rules (css-display-none)
            for rule in elementRules {
                // Strip www. prefix for better domain matching
                var domain = rule.domain
                if domain.hasPrefix("www.") {
                    domain = String(domain.dropFirst(4))
                }
                print("   Adding element rule: \(rule.domain) -> *\(domain) ## \(rule.selector)")
                allRules.append([
                    "trigger": [
                        "url-filter": ".*",
                        "if-domain": ["*\(domain)"]
                    ],
                    "action": [
                        "type": "css-display-none",
                        "selector": rule.selector
                    ]
                ])
            }

            let data = try JSONSerialization.data(withJSONObject: allRules,
                                                  options: [.prettyPrinted])

            print("📁 Writing to: \(rulesURL.path)")
            try data.write(to: rulesURL, options: .atomic)
            print("✅ File written successfully (\(data.count) bytes)")

            // Print the actual JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 JSON content:")
                print(jsonString)
            }

            // Verify file exists and is readable
            if FileManager.default.fileExists(atPath: rulesURL.path) {
                print("✅ File exists at path")
                if let attrs = try? FileManager.default.attributesOfItem(atPath: rulesURL.path) {
                    print("   File size: \(attrs[.size] ?? "unknown") bytes")
                }
            } else {
                print("❌ File does NOT exist after write!")
            }

            let extensionID = "-0x.ExactBlocker.ExactBlockerBlocker"
            print("🔄 Reloading content blocker: \(extensionID)")

            SFContentBlockerManager.reloadContentBlocker(withIdentifier: extensionID) { error in
                if let error {
                    print("❌ Reload FAILED: \(error)")
                    print("   Error domain: \(error._domain)")
                    print("   Error code: \(error._code)")
                    print("   ⚠️  Make sure extension is enabled in Settings > Safari > Extensions")
                } else {
                    print("✅ Content blocker reloaded successfully!")
                }
                print("═══════════════════════════════════════════════════════════")
            }

        } catch {
            print("❌ Could not write rules: \(error)")
            print("═══════════════════════════════════════════════════════════")
        }
    }
}

//
//  ContentBlockerRequestHandler.swift
//  ExactBlockerBlocker
//
//  Created by Alex Morris on 4/27/25.
//

import UIKit
import MobileCoreServices
import os.log

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {

    private let logger = Logger(subsystem: "-0x.ExactBlocker.ExactBlockerBlocker", category: "ContentBlocker")

    func beginRequest(with context: NSExtensionContext) {
        logger.info("🚀 ContentBlockerRequestHandler.beginRequest() called by Safari")

        // Locate blockerList.json in the shared App‑Group container
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.alexmorris10x.exactblocker") else {
            logger.error("❌ Could not access app group container!")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        let rulesURL = containerURL.appendingPathComponent("blockerList.json")
        logger.info("📁 Looking for rules at: \(rulesURL.path)")

        // Check if file exists
        if FileManager.default.fileExists(atPath: rulesURL.path) {
            logger.info("✅ Rules file exists")

            // Log file contents for debugging
            if let data = try? Data(contentsOf: rulesURL),
               let jsonString = String(data: data, encoding: .utf8) {
                logger.info("📄 Rules content (\(data.count) bytes):\n\(jsonString)")
            }
        } else {
            logger.error("❌ Rules file does NOT exist at path!")
            // Return empty rules array so Safari doesn't fail
            let emptyRules = "[]".data(using: .utf8)!
            let tempURL = containerURL.appendingPathComponent("empty.json")
            try? emptyRules.write(to: tempURL)
            let attachment = NSItemProvider(contentsOf: tempURL)!
            let item = NSExtensionItem()
            item.attachments = [attachment]
            context.completeRequest(returningItems: [item], completionHandler: nil)
            return
        }

        // Pass the rules back to Safari
        guard let attachment = NSItemProvider(contentsOf: rulesURL) else {
            logger.error("❌ Could not create NSItemProvider from rules file")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        let item = NSExtensionItem()
        item.attachments = [attachment]
        logger.info("✅ Returning rules to Safari")
        context.completeRequest(returningItems: [item], completionHandler: nil)
    }

}

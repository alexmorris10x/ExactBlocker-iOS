//
//  SafariWebExtensionHandler.swift
//  ExactBlockerWebExtension
//
//  Created by Alex Morris on 12/26/25.
//

import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        // 1. READ RULES FROM APP GROUP
        let defaults = UserDefaults(suiteName: "group.com.alexmorris10x.exactblocker")
        let rulesData = defaults?.data(forKey: "ElementRulesForExtension")

        var responseData: [String: Any] = ["status": "no_data"]

        // 2. PREPARE DATA
        if let data = rulesData,
           let rules = try? JSONSerialization.jsonObject(with: data, options: []) {
            responseData = ["status": "success", "rules": rules]
            os_log(.default, "✅ ExactBlocker: Found rules in App Group!")
        } else {
            os_log(.default, "⚠️ ExactBlocker: No rules found in App Group.")
        }

        // 3. SEND RESPONSE BACK TO JS
        let response = NSExtensionItem()
        if #available(iOS 15.0, macOS 11.0, *) {
            response.userInfo = [ SFExtensionMessageKey: responseData ]
        } else {
            response.userInfo = [ "message": responseData ]
        }

        context.completeRequest(returningItems: [ response ], completionHandler: nil)
    }
}

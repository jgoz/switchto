//
//  main.swift
//  switchto
//
//  Created by John Gozde on 2021-05-11.
//
//

import ArgumentParser
import Cocoa
import CoreFoundation
import Foundation

struct SwitchTo: ParsableCommand {
    @Argument(help: "List of application names/bundle IDs to activate")
    var applications: [String]

    @Flag(help: "Activate the most recently used application matching any of the specified IDs")
    var recent = false

    mutating func run() throws {
        let workspace = NSWorkspace.shared

        var appNamesInOrder: [String] = [];
        if let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
            for dict in info {
                let layer = dict[kCGWindowLayer as String] as! Int
                if layer == 0 {
                    let name = dict[kCGWindowOwnerName as String]
                    if let name = name {
                        appNamesInOrder.append((name as! String).replacingOccurrences(of: ".app", with: ""))
                    }
                }
            }
        }

        let appNameLookup = Set(appNamesInOrder)
        let runningApps = workspace.runningApplications
                .filter({ app in app.localizedName != nil && appNameLookup.contains(app.localizedName!) })
        let runningAppsLookup = Dictionary<String, NSRunningApplication>(uniqueKeysWithValues: runningApps.map {
            ($0.localizedName!, $0)
        })

        let runningAppsInOrder = appNamesInOrder.map({ runningAppsLookup[$0]! })

        if (recent) {
            for app in runningAppsInOrder {
                if let bundleID = app.bundleIdentifier, let name = app.localizedName {
                    if applications.contains(bundleID) || applications.contains(name) {
                        app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
                        return
                    }
                }
            }
        } else {
            for id in applications {
                let app = runningAppsInOrder.first(where: { $0.bundleIdentifier == id || $0.localizedName == id })
                if let app = app {
                    app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
                    return
                }
            }
        }
        
        throw ExitCode.failure
    }
}

SwitchTo.main()

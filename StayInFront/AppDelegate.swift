//
//  AppDelegate.swift
//  StayInFront
//
//  Created by jun.ogino on 2023/11/08.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var toggleMenuHandler: (() -> Void)?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let stayInFrontMenu = NSMenuItem(title: "Stay in Front", action: #selector(menuClicked), keyEquivalent: "stay in front")
        stayInFrontMenu.target = self
        stayInFrontMenu.state = .on

        if let fileMenu = NSApp.menu?.items.first(where: {$0.title == "Window" })?.submenu {
            fileMenu.addItem(stayInFrontMenu)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    @IBAction func menuClicked(_ sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
        toggleMenuHandler?()
    }
}


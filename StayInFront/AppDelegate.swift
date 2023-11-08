//
//  AppDelegate.swift
//  StayInFront
//
//  Created by jun.ogino on 2023/11/08.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    
    @IBOutlet weak var stayInFrontMenu: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    @IBAction func menuClicked(_ sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
        NotificationCenter.default.post(name: .init("StayInFront"), object: nil)
    }
}


//
//  AppDelegate.swift
//  Helium Lift
//
//  Modified by Justin Mitchell on 7/12/15.
//  Copyright (c) 2015 Justin Mitchell. All rights reserved.
//

import Cocoa
import CoreGraphics

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    @IBOutlet weak var magicURLMenu: NSMenuItem!
    @IBOutlet weak var menuBarMenu: NSMenu!
    
    var statusBar = NSStatusBar.system
    var statusBarItem : NSStatusItem = NSStatusItem()
    var defaultWindow:NSWindow!
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        
        // This has to be called before the application is finished launching
        // or something (the sandbox maybe?) prevents it from registering.
        // I moved it from the applicationDidFinishLaunching method.
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(AppDelegate.handleURLEvent(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        statusBarItem = statusBar.statusItem(withLength: -1)
        statusBarItem.menu = menuBarMenu
        statusBarItem.image = NSImage(named: NSImage.Name(rawValue: "menuBar"))
        
        // Insert code here to initialize your application
        
        defaultWindow = NSApplication.shared.windows.first as NSWindow?
        defaultWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelKey.mainMenuWindow.rawValue) - 1)
        defaultWindow.collectionBehavior = [NSWindow.CollectionBehavior.fullScreenAuxiliary, NSWindow.CollectionBehavior.canJoinAllSpaces, NSWindow.CollectionBehavior.fullScreenAuxiliary]
        
        magicURLMenu.state = UserDefaults.standard.bool(forKey: "disabledMagicURLs") ? NSControl.StateValue.off : NSControl.StateValue.on
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
    
    @IBAction func magicURLRedirectToggled(_ sender: NSMenuItem) {
        sender.state = (sender.state == NSControl.StateValue.on) ? NSControl.StateValue.off : NSControl.StateValue.on
        UserDefaults.standard.set((sender.state == NSControl.StateValue.off), forKey: "disabledMagicURLs")
    }
    
    
    //MARK: - handleURLEvent
    // Called when the App opened via URL.
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        
        // There were a lot of strange Optionals being used in this method,
        // including a bunch of stuff that was being force-unwrapped.
        // I just cleaned it up a little, but didn't make any substantive changes.
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue {
            
            let url = urlString.components(separatedBy: "heliumlift://openURL=").last!
            if let urlObject = URL(string: url) {
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "HeliumLoadURL"), object: urlObject)
                
            }
        } else {
            print("No valid URL to handle")
        }
        
        
    }
    
    var alpha: CGFloat = 0.6 { //default
        didSet {
            if translucent {
                panel.alphaValue = alpha
            }
        }
    }
    
    var translucent: Bool = false {
        didSet {
            if !NSApplication.shared.isActive {
                panel.ignoresMouseEvents = translucent
            }
            if translucent {
                panel.isOpaque = false
                panel.alphaValue = alpha
            }
            else {
                panel.isOpaque = true
                panel.alphaValue = 1.0
            }
        }
    }
    
    
    var panel: NSPanel! {
        get {
            return (self.defaultWindow as! NSPanel)
        }
    }
    
    var webViewController: WebViewController {
        get {
            return self.defaultWindow?.contentViewController as! WebViewController
        }
    }
    
    func windowDidLoad() {
        panel.isFloatingPanel = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.willResignActive), name: NSApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didUpdateTitle(_:)), name: NSNotification.Name(rawValue: "HeliumUpdateTitle"), object: nil)
 
    }
    
    //MARK: IBActions
    
    @IBAction func translucencyPress(_ sender: NSMenuItem) {
        if sender.state == NSControl.StateValue.on  {
            sender.state = NSControl.StateValue.off
            didDisableTranslucency()
        }
        else {
            sender.state = NSControl.StateValue.on
            didEnableTranslucency()
        }
    }
    
    @IBAction func percentagePress(_ sender: NSMenuItem) {
        for button in sender.menu!.items{
            (button ).state = NSControl.StateValue.off
        }
        sender.state = NSControl.StateValue.on
        let value = sender.title.substring(to: sender.title.characters.index(sender.title.endIndex, offsetBy: -1))
        if let alpha = Int(value) {
            didUpdateAlpha(NSNumber(value: alpha as Int))
        }
    }
    
    @IBAction func openLocationPress(_ sender: AnyObject) {
        print("location requested...")
        didRequestLocation()
    }
    
    @IBAction func openFilePress(_ sender: AnyObject) {
        didRequestFile()
    }
    
    @IBAction func goHomePressed(_ sender: NSMenuItem) {
        print("goHomePressed...")
        webViewController.clear()
    }
    
    @IBAction func changeVisible(_ sender: AnyObject) {
        print("Command Y pressed")
        let nWindow = (NSApplication.shared.windows.first! as NSWindow)
        if(nWindow.isVisible) { nWindow.setIsVisible(false); return }
        else { nWindow.setIsVisible(true); return }
    }
    
    //MARK: Actual functionality
    @objc func didUpdateTitle(_ notification: Notification) {
        if let title = notification.object as? String {
            panel.title = title
        }
    }
    
    func didRequestFile() {
        
        let open = NSOpenPanel()
        open.allowsMultipleSelection = false
        open.canChooseFiles = true
        open.canChooseDirectories = false
        open.allowedFileTypes = ["mov","mp4","ogg","avi","m4v","mpg","mpeg"]
        
        let response:NSApplication.ModalResponse = open.runModal()
        
        if response == NSApplication.ModalResponse.OK {
            if let url = open.url {
                webViewController.loadURL(url)
            }
        }
    }
    
    
    func didRequestLocation() {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.informational
        alert.messageText = "Enter Destination URL"
        
        let urlField = NSTextField()
        urlField.frame = NSRect(x: 0, y: 0, width: 300, height: 20)
        
        alert.accessoryView = urlField
        alert.addButton(withTitle: "Load")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: defaultWindow!, completionHandler: { response in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                // Load
                var text = (alert.accessoryView as! NSTextField).stringValue
                
                if !(text.lowercased().hasPrefix("http://") || text.lowercased().hasPrefix("https://")) {
                    text = "http://" + text
                }
                
                if let url = URL(string: text) {
                    self.webViewController.loadURL(url)
                }
            }
        })
    }
    
    @objc func didBecomeActive() {
        panel.ignoresMouseEvents = false
    }
    
    @objc func willResignActive() {
        if translucent {
            panel.ignoresMouseEvents = true
        }
    }
    
    func didEnableTranslucency() {
        translucent = true
    }
    
    func didDisableTranslucency() {
        translucent = false
    }
    
    func didUpdateAlpha(_ newAlpha: NSNumber) {
        alpha = CGFloat(newAlpha.doubleValue) / CGFloat(100.0)
    }
}


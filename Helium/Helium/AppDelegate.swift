//
//  AppDelegate.swift
//  Helium Lift
//
//  Modified by Justin Mitchell on 7/12/15.
//  Copyright © 2015-2019 Justin Mitchell. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    @IBOutlet weak var magicURLMenu: NSMenuItem!
    @IBOutlet weak var menuBarMenu: NSMenu!

    var statusBar = NSStatusBar.system
    var statusBarItem = NSStatusItem()
    var defaultWindow: NSWindow!

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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        statusBarItem = statusBar.statusItem(withLength: -1)
        statusBarItem.menu = menuBarMenu
        statusBarItem.image = NSImage(named: "menuBar")

		defaultWindow = NSApplication.shared.windows.first
        defaultWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelKey.mainMenuWindow.rawValue) - 1)
        defaultWindow.collectionBehavior = [NSWindow.CollectionBehavior.fullScreenAuxiliary, NSWindow.CollectionBehavior.canJoinAllSpaces, NSWindow.CollectionBehavior.fullScreenAuxiliary]

		magicURLMenu.state = UserDefaults.standard.bool(forKey: UserSetting.disabledMagicURLs.userDefaultsKey) ? NSControl.StateValue.off : NSControl.StateValue.on

		windowDidLoad()
    }

	func applicationWillTerminate(_ notification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func magicURLRedirectToggled(_ sender: NSMenuItem) {
        sender.state = (sender.state == NSControl.StateValue.on) ? NSControl.StateValue.off : NSControl.StateValue.on
        UserDefaults.standard.set((sender.state == NSControl.StateValue.off), forKey: UserSetting.disabledMagicURLs.userDefaultsKey)
    }

    // MARK: -

	// Called when the App opened via URL.
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        if let eventURL = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue {
            let urlString = eventURL.components(separatedBy: "heliumlift://openURL=").last!
			NotificationCenter.default.post(name: Notification.Name("HeliumLoadURL"), object: urlString)
        } else {
            NSLog("Error: No valid url in apple event.")
        }
    }

    var alpha: CGFloat = 0.6 {
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
        return (self.defaultWindow as! NSPanel)
    }

    var webViewController: WebViewController {
		return self.defaultWindow?.contentViewController as! WebViewController
    }
    
    func windowDidLoad() {
        panel.isFloatingPanel = true

        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.willResignActive), name: NSApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didUpdateTitle(_:)), name: NSNotification.Name("HeliumUpdateTitle"), object: nil)
	}

	// MARK: -
	// MARK: IBActions
    
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
        let value = sender.title[..<sender.title.index(sender.title.endIndex, offsetBy: -1)]
        if let alpha = Int(value) {
            didUpdateAlpha(NSNumber(value: alpha as Int))
        }
    }
    
    @IBAction func openLocationPress(_ sender: AnyObject) {
        didRequestLocation()
    }
    
    @IBAction func openFilePress(_ sender: AnyObject) {
        didRequestFile()
    }
    
    @IBAction func goHomePressed(_ sender: NSMenuItem) {
        webViewController.goToHomepage()
    }

	@IBAction func changeVisible(_ sender: AnyObject) {
		if let nWindow = NSApplication.shared.windows.first {
			if (nWindow.isVisible) {
				nWindow.setIsVisible(false)
			} else {
				nWindow.setIsVisible(true)
			}
		}
	}

	// MARK: -
    // MARK: Actual functionality

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

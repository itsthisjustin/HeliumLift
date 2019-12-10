//
//  AppDelegate.swift
//  Helium Lift
//
//  Modified by Justin Mitchell on 7/12/15.
//  Copyright © 2015-2019 Justin Mitchell. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {

	@IBOutlet weak var menuBarMenu: NSMenu!

	var defaultWindow: NSWindow!
	var statusBar = NSStatusBar.system
	var statusBarItem = NSStatusItem()

	// MARK: -
	// MARK: NSApplicationDelegate

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
		statusBarItem.image = NSImage(named: "MenuIcon")

		defaultWindow = NSApplication.shared.windows.first
		defaultWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelKey.mainMenuWindow.rawValue) - 1)
		defaultWindow.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces, .fullScreenAuxiliary]

		windowDidLoad()
	}

	func applicationWillTerminate(_ notification: Notification) {
		// Insert code here to tear down your application
	}

	// MARK: -

	// Called when the App opened via URL.
	@objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor)
	{
		if let originalURL = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue {
			var eventURL = originalURL
			var prefix: String
			var wasHeliumURL = false

			// remove the 'heliumlift://' prefix
			prefix = "heliumlift://"
			if (eventURL.lowercased().hasPrefix(prefix)) {
				eventURL = String(eventURL.dropFirst(prefix.count))
				wasHeliumURL = true
			}
			// remove the 'helium://' prefix
			prefix = "helium://"
			if (eventURL.lowercased().hasPrefix(prefix)) {
				eventURL = String(eventURL.dropFirst(prefix.count))
				wasHeliumURL = true
			}

			if (wasHeliumURL) {
				// remove the 'openurl=' prefix
				prefix = "openurl="
				if (eventURL.lowercased().hasPrefix(prefix)) {
					eventURL = String(eventURL.dropFirst(prefix.count))
				}
				// fix Safari's modified urls
				prefix = "http//"
				if (eventURL.lowercased().hasPrefix(prefix)) {
					eventURL = String(eventURL.dropFirst(prefix.count))
					eventURL = ("http://" + eventURL)
				}
				prefix = "https//"
				if (eventURL.lowercased().hasPrefix(prefix)) {
					eventURL = String(eventURL.dropFirst(prefix.count))
					eventURL = ("https://" + eventURL)
				}
			}

			// safety check
			guard (eventURL.lowercased().hasPrefix("http://") || eventURL.lowercased().hasPrefix("https://")) else {
				NSLog("Error: Get URL Apple Event did not contain a valid URL. (\(originalURL))")
				return
			}

			// open the url
			NotificationCenter.default.post(name: WebViewOpenURLNotification, object: eventURL)
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
			if translucent {
				panel.alphaValue = alpha
				panel.ignoresMouseEvents = true
				panel.isOpaque = false
			} else {
				panel.alphaValue = 1.0
				panel.ignoresMouseEvents = false
				panel.isOpaque = true
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

		NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didUpdateTitle(_:)), name: NSNotification.Name("HeliumUpdateTitle"), object: nil)
	}

	// MARK: -
	// MARK: IBActions

	@IBAction func changedOpacity(_ sender: NSMenuItem) {
		for button in sender.menu!.items {
			button.state = .off
		}
		sender.state = .on
		let value = sender.title[..<sender.title.index(sender.title.endIndex, offsetBy: -1)]
		if let alpha = Double(value) {
			didUpdateAlpha(alpha)
		}
	}

	@IBAction func openDashboard(_ sender: Any?) {
		webViewController.goToHomepage()
	}

	@IBAction func openFile(_ sender: Any?) {
		didRequestFile()
	}

	@IBAction func openWebLocation(_ sender: Any?) {
		didRequestLocation()
	}

	@IBAction func toggleMagicURLs(_ sender: Any?) {
		let userDefaults = UserDefaults.standard
		let useMagicURLs = userDefaults.bool(forKey: UserSetting.useMagicURLs.rawValue)
		userDefaults.set(!useMagicURLs, forKey: UserSetting.useMagicURLs.rawValue)
	}

	@IBAction func toggleTranslucency(_ sender: Any?) {
		translucent = !translucent
	}

	@IBAction func toggleVisibility(_ sender: Any?) {
		defaultWindow.setIsVisible(!defaultWindow.isVisible)
	}

	@IBAction func zoomIn(_ sender: Any?) {
		webViewController.zoomIn()
	}

	@IBAction func zoomOut(_ sender: Any?) {
		webViewController.zoomOut()
	}

	@IBAction func zoomReset(_ sender: Any?) {
		webViewController.zoomReset()
	}

	// MARK: -
	// MARK: NSMenuItemValidation

	func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
	{
		if (menuItem.action == #selector(AppDelegate.toggleMagicURLs)) {
			menuItem.state = UserDefaults.standard.bool(forKey: UserSetting.useMagicURLs.rawValue) ? .on : .off
		} else if (menuItem.action == #selector(AppDelegate.toggleTranslucency)) {
			menuItem.state = translucent ? .on : .off
		} else if (menuItem.action == #selector(AppDelegate.toggleVisibility)) {
			if (defaultWindow.isVisible) {
				menuItem.title = "Hide Window"
			} else {
				menuItem.title = "Show Window"
			}
		}

		return true
	}

	// MARK: -
	// MARK: Actual functionality

	func didRequestFile() {
		let open = NSOpenPanel()
		open.allowsMultipleSelection = false
		open.canChooseFiles = true
		open.canChooseDirectories = false
		open.allowedFileTypes = ["mov", "mp4", "ogg", "avi", "m4v", "mpg", "mpeg"]

		let response = open.runModal()
		if response == .OK {
			if let url = open.url {
				webViewController.loadURL(url)
			}
		}
	}

	func didRequestLocation() {
		let alert = NSAlert()
		alert.alertStyle = .informational
		alert.messageText = "Enter Destination URL"

		let urlField = NSTextField()
		urlField.frame = NSRect(x: 0, y: 0, width: 300, height: 20)

		alert.accessoryView = urlField
		alert.addButton(withTitle: "Load")
		alert.addButton(withTitle: "Cancel")
		alert.beginSheetModal(for: defaultWindow!, completionHandler: { response in
			if response == .alertFirstButtonReturn {
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

	func didUpdateAlpha(_ newAlpha: Double) {
		alpha = CGFloat(newAlpha / 100.0)
	}

	@objc func didUpdateTitle(_ notification: Notification) {
		if let title = notification.object as? String {
			panel.title = title
		}
	}

}

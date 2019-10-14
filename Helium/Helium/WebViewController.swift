//
//  ViewController.swift
//  Helium Lift
//
//  Modified by Justin Mitchell on 7/12/15.
//  Copyright © 2015-2019 Justin Mitchell. All rights reserved.
//

import Cocoa
import WebKit

class WebViewController: NSViewController, WKNavigationDelegate {

	let webView = WKWebView()

    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addTrackingRect(view.bounds, owner: self, userData: nil, assumeInside: false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(WebViewController.loadURLObject(_:)), name: NSNotification.Name(rawValue: "HeliumLoadURL"), object: nil)
        
        // Layout webview
        view.addSubview(webView)
        webView.frame = view.bounds
        webView.autoresizingMask = [NSView.AutoresizingMask.height, NSView.AutoresizingMask.width]
        
        // Allow plug-ins such as silverlight
        webView.configuration.preferences.plugInsEnabled = true
        
        // Custom user agent string for Netflix HTML5 support
        webView._customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/601.6.17 (KHTML, like Gecko) Version/9.1.1 Safari/601.6.17"

        // Setup magic URLs
        webView.navigationDelegate = self
        
        // Allow zooming
        webView.allowsMagnification = true

        // Allow back and forth
        webView.allowsBackForwardNavigationGestures = true

        // Listen for load progress
        webView.addObserver(self, forKeyPath:  #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: .new, context: nil)

        clear()
    }

    // MARK: Actions
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.title {
        case "Back":
            return webView.canGoBack
        case "Forward":
            return webView.canGoForward
        default:
            return true
        }
    }
    
    @IBAction func backPress(_ sender: AnyObject) {
        webView.goBack()
    }
    
    @IBAction func forwardPress(_ sender: AnyObject) {
        webView.goForward()
    }
    
    func zoomIn() {
        webView.magnification += 0.1
    }
    
    func zoomOut() {
        webView.magnification -= 0.1
    }
    
    func resetZoom() {
        webView.magnification = 1
    }
    
    @IBAction func reloadPress(_ sender: Any) {
        requestedReload()
    }
    
    @IBAction func clearPress(_ sender: Any) {
        clear()
    }
    
    @IBAction func resetZoomLevel(_ sender: Any) {
        resetZoom()
    }
    @IBAction func zoomIn(_ sender: Any) {
        zoomIn()
    }
    @IBAction func zoomOut(_ sender: Any) {
        zoomOut()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    internal func loadAlmostURL(_ text: String) {
        var text = text
        if !(text.lowercased().hasPrefix("http://") || text.lowercased().hasPrefix("https://")) {
            text = "http://" + text
        }
        
        if let url = URL(string: text) {
            loadURL(url)
        }
    }
    
    // MARK: Loading

    func loadURL(_ url: URL) {
		var urlToLoad = url

		// rewrite the url
		if shouldRedirect, let newURL = rewriteURL(urlToLoad) {
			urlToLoad = newURL
		}

		// load the url
		webView.load(URLRequest(url: urlToLoad))
    }

	// MARK: -
	// MARK: loadURLObject
    @objc func loadURLObject(_ urlObject: Notification) {
        
        // This is where the work gets done - it grabs everything after
        // "openURL=" from the urlObject, makes a new NSURL out of it
        // and sends it to loadURL.
        
//        if let url = urlObject.object as? NSURL,
//            let lastPart = url.absoluteString.componentsSeparatedByString("openURL=").last,
//            let newURL = NSURL(string: lastPart) {
//                loadURL(newURL);
//        }
        
        if let url = urlObject.object as? URL {
            loadAlmostURL(url.absoluteString)
        }
    }
    
    func requestedReload() {
        webView.reload()
    }
    
    // MARK: Webview functions
    func clear() {
        if let homePage = UserDefaults.standard.string(forKey: UserSetting.homePageURL.userDefaultsKey) {
            loadAlmostURL(homePage)
        } else {
//            loadURL(URL(string: "http://heliumlift.duet.to/start.html")!)
//            loadURL(URL(string: "http://heliumlift.bitballoon.com")!)
			loadURL(URL(string: "https://heliumlift.netlify.com")!)
        }
    }
    
    var shouldRedirect: Bool {
        return !UserDefaults.standard.bool(forKey: UserSetting.disabledMagicURLs.userDefaultsKey)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    }

	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		NSLog("\(error.localizedDescription)")
	}

	func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
	}

	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

		// rewrite the url (if necessary)
		if shouldRedirect, let originalURL = webView.url, let newURL = rewriteURL(originalURL) {
			// if the url was rewritten, cancel the load and start a new one
			decisionHandler(WKNavigationActionPolicy.cancel)
			webView.load(URLRequest(url: newURL))
			return
		}

		decisionHandler(WKNavigationActionPolicy.allow)
	}

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        if let pageTitle = webView.title {
            var title = pageTitle;
            if title.isEmpty { title = "HeliumLift" }
            let notif = Notification(name: Notification.Name(rawValue: "HeliumUpdateTitle"), object: title);
            NotificationCenter.default.post(notif)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		NSLog("\(error.localizedDescription)")
    }

	@objc override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

		if keyPath == #keyPath(WKWebView.estimatedProgress) {
			let percent = webView.estimatedProgress * 100.0
			let title = (percent == 100.0) ? NSString(format: "Loading... %.2f%%", percent) : "HeliumLift"
			let notification = Notification(name: Notification.Name("HeliumUpdateTitle"), object: title)
			NotificationCenter.default.post(notification)
		} else if keyPath == #keyPath(WKWebView.url) {
			if shouldRedirect, let originalURL = webView.url, let newURL = rewriteURL(originalURL) {
				// stop loading the page
				webView.stopLoading()
				DispatchQueue.main.async {
					// load the rewritten url
					self.webView.load(URLRequest(url: newURL))
				}
			}
		}
	}

	// MARK: -

	private func rewriteURL(_ url: URL) -> URL?
	{
		// parse the url into components
		guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
			return nil
		}

		let urlString = url.absoluteString
		var modified = urlString

		// rewrite youtube links
		if (components.host == "youtu.be") || (components.host == "youtube.com") || (components.host == "www.youtube.com") {
			components = rewriteYouTubeLinks(components)
			if let rewrittenURL = components.url {
				modified = rewrittenURL.absoluteString
			}
		} else {
			// rewrite other links
			modified = modified.replacePrefix("https://vimeo.com/", replacement: "http://player.vimeo.com/video/")
			modified = modified.replacePrefix("http://v.youku.com/v_show/id_", replacement: "http://player.youku.com/embed/")
			modified = modified.replacePrefix("https://www.twitch.tv/", replacement: "https://player.twitch.tv?html5&channel=")
			modified = modified.replacePrefix("http://www.dailymotion.com/video/", replacement: "http://www.dailymotion.com/embed/video/")
			modified = modified.replacePrefix("http://dai.ly/", replacement: "http://www.dailymotion.com/embed/video/")
		}

		// return the modified url
		if urlString != modified {
			return URL(string: modified)
		}

		return nil
	}

	private func rewriteYouTubeLinks(_ urlComponents: URLComponents) -> URLComponents
	{
		var components = urlComponents
		var queryItems = components.queryItems ?? [URLQueryItem]()
		var videoID: String?

		// parse the video id from youtube urls
		if components.host!.hasSuffix("youtu.be") {
			// youtu.be links put the video id in the path
			let idIndex = components.path.index(components.path.startIndex, offsetBy: 1)
			videoID = String(components.path[idIndex...])
		} else if components.path.hasPrefix("/embed/") {
			// embed links contain the video id in the path
			let idIndex = components.path.index(components.path.startIndex, offsetBy: 7)
			videoID = String(components.path[idIndex...])
		} else if components.path.hasPrefix("/v/") {
			// video links contain the video id in the path
			let idIndex = components.path.index(components.path.startIndex, offsetBy: 3)
			videoID = String(components.path[idIndex...])
		} else {
			// check the query items for the video id
			for item in queryItems {
				if item.name == "v" {
					videoID = item.value
					break
				}
			}
			if videoID != nil {
				// remove the video id from the query items
				queryItems.removeAll(where: { $0.name == "v" })
			}
		}

		// set youtube links to use https
		if (components.scheme == "http") {
			components.scheme = "https"
		}

		// rewrite time parameters as 'start' parameters
		for item in queryItems {
			if item.name == "t" {
				if let secondsString = item.value {
					let seconds = parseYouTubeTimeParameter(secondsString)
					if seconds > 0 {
						queryItems.append(URLQueryItem(name: "start", value: String(seconds)))
					}
				}
				break
			}
		}
		queryItems.removeAll(where: { $0.name == "t" })

		// only rewrite links that contain a valid video id
		if let videoID = videoID, (videoID.count == 11) {
			// make sure that autoplay is set
			queryItems.removeAll(where: { $0.name == "autoplay" })
			queryItems.append(URLQueryItem(name: "autoplay", value: "1"))

			// rewrite links to use standard video pages
			components.host = "www.youtube.com"
			components.path = "/watch"
			queryItems.append(URLQueryItem(name: "v", value: videoID))
/*
			// rewrite links to use embedded likns
			components.path = "/embed/\(videoID)"
*/
		}

		// update the query items
		components.queryItems = (queryItems.count > 0) ? queryItems : nil

		return components
	}

    // Convert a YouTube video url time paramenter into seconds. (ie. "t=1m2s" -> 62)

	private func parseYouTubeTimeParameter(_ timeString: String) -> Int
	{
		var currentIndex = timeString.startIndex
		var timeInSeconds = 0

		// get the hours
		if let hoursIndex = timeString.firstIndex(of: "h") {
			if let hours = Int(timeString[currentIndex ..< hoursIndex]) {
				currentIndex = timeString.index(hoursIndex, offsetBy: 1)
				timeInSeconds = (hours * 60 * 60)
			}
		}

		// get the minutes
		if let minutesIndex = timeString.firstIndex(of: "m") {
			if let minutes = Int(timeString[currentIndex ..< minutesIndex]) {
				currentIndex = timeString.index(minutesIndex, offsetBy: 1)
				timeInSeconds = (minutes * 60)
			}
		}

		// get the seconds
		if let secondsIndex = timeString.firstIndex(of: "s") {
			if let seconds = Int(timeString[currentIndex ..< secondsIndex]) {
				currentIndex = timeString.index(secondsIndex, offsetBy: 1)
				timeInSeconds += seconds
			}
		}

		return timeInSeconds
	}

}

// MARK: -

extension String {

	func replacePrefix(_ prefix: String, replacement: String) -> String {
		if hasPrefix(prefix) {
			return replacement + substring(from: prefix.endIndex)
		} else {
			return self
		}
	}

}

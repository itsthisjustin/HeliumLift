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

	let dashboardURL = "https://heliumlift.netlify.com"
	let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1.2 Safari/605.1.15"

	let webView = WKWebView()

	// MARK: -
	// MARK: NSViewController

	override var representedObject: Any? {
		didSet {
			// Update the view, if already loaded.
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.addTrackingRect(view.bounds, owner: self, userData: nil, assumeInside: false)

		NotificationCenter.default.addObserver(self, selector: #selector(WebViewController.loadURLNotification(_:)), name: NSNotification.Name("HeliumLoadURL"), object: nil)

		// Layout webview
		view.addSubview(webView)
		webView.frame = view.bounds
		webView.autoresizingMask = [NSView.AutoresizingMask.height, NSView.AutoresizingMask.width]

		// Allow plug-ins such as silverlight
		webView.configuration.preferences.plugInsEnabled = true

		// set the user agent
		if #available(OSX 10.11, *) {
			webView.customUserAgent = userAgent
		} else {
			webView._customUserAgent = userAgent
		}

		// Setup magic URLs
		webView.navigationDelegate = self

		// Allow zooming
		webView.allowsMagnification = true

		// Allow back and forth
		webView.allowsBackForwardNavigationGestures = true

		// Listen for load progress
		webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
		webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: .new, context: nil)

		goToHomepage()
	}

	// MARK: -
	// MARK: IBActions

	@IBAction func backPress(_ sender: AnyObject) {
		webView.goBack()
	}

	@IBAction func clearPress(_ sender: Any) {
		goToHomepage()
	}

	@IBAction func forwardPress(_ sender: AnyObject) {
		webView.goForward()
	}

	@IBAction func reloadPress(_ sender: Any?) {
		requestedReload()
	}

	// MARK: -

	func goToHomepage() {
		if let homePage = UserDefaults.standard.string(forKey: UserSetting.homePageURL.rawValue) {
			if let homePageURL = URL(string: homePage) {
				loadURL(homePageURL)
			}
		} else {
			// open the dashboard url
			loadURL(URL(string: dashboardURL)!)
		}
	}

	func loadURL(_ url: URL) {
		var urlToLoad = url

		// rewrite the url
		if shouldRewriteURLs, let newURL = rewriteURL(urlToLoad) {
			urlToLoad = newURL
		}

#if DEBUG
		if url.absoluteString != urlToLoad.absoluteString {
			print("loadURL: (rewritten): \(url.absoluteString) -> \(urlToLoad.absoluteString)")
		} else {
			print("loadURL: \(url.absoluteString)")
		}
#endif // DEBUG

		// load the url
		webView.load(URLRequest(url: urlToLoad))
	}

	@objc func loadURLNotification(_ notification: Notification) {

		// get the url string from the notification
		guard var urlString = notification.object as? String else {
			NSLog("Error: No url string in open url notification.")
			return
		}

		// make sure the string has the scheme
		if (urlString.hasPrefix("http://") == false) || (urlString.hasPrefix("https://") == false) {
			urlString = ("https://" + urlString)
		}

		// create the url
		guard let url = URL(string: urlString) else {
			NSLog("Error: Unable to create url from notification.")
			return
		}

		// open the url
		loadURL(url)
	}

	func requestedReload() {
		webView.reload()
	}

	var shouldRewriteURLs: Bool {
		return UserDefaults.standard.bool(forKey: UserSetting.useMagicURLs.rawValue)
	}

	@objc override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

		if keyPath == #keyPath(WKWebView.estimatedProgress) {
			// update the loading progress
			let percent = Int(round(webView.estimatedProgress * 100.0))
			let title = (percent == 100) ? "Loading... \(percent)%" : "HeliumLift"
			let notification = Notification(name: Notification.Name("HeliumUpdateTitle"), object: title)
			NotificationCenter.default.post(notification)
		} else if keyPath == #keyPath(WKWebView.url) {
			// catch and rewrite urls loaded through page javascript
			if shouldRewriteURLs, let originalURL = webView.url, let newURL = rewriteURL(originalURL) {
#if DEBUG
				print("webView.url: (rewritten): \(originalURL.absoluteString) -> \(newURL.absoluteString)")
#endif // DEBUG
				// stop loading the page
				webView.stopLoading()
				DispatchQueue.main.async {
					// load the rewritten url
					self.webView.load(URLRequest(url: newURL))
				}
			}
		}
	}

	func zoomIn() {
		webView.magnification += 0.1
	}

	func zoomOut() {
		webView.magnification -= 0.1
	}

	func zoomReset() {
		webView.magnification = 1.0
	}

	// MARK: -
	// MARK: WKNavigationDelegate

	func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
	}

	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		NSLog("\(error.localizedDescription)")
	}

	func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
	}

	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		// get the request url
		guard let requestURL = navigationAction.request.url else {
			NSLog("Error: Could not get url for navigation action.")
			decisionHandler(WKNavigationActionPolicy.allow)
			return
		}

		// rewrite the url (if necessary)
		if shouldRewriteURLs, let newURL = rewriteURL(requestURL) {
#if DEBUG
			print("decidePolicyFor: (rewritten): \(requestURL.absoluteString) - > \(newURL.absoluteString)")
#endif // DEBUG
			// if the url was rewritten, cancel the load and start a new one
			decisionHandler(WKNavigationActionPolicy.cancel)
			webView.load(URLRequest(url: newURL))
			return
		}

#if DEBUG
		print("decidePolicyFor: (allowed): \(requestURL.absoluteString)")
#endif // DEBUG

		decisionHandler(WKNavigationActionPolicy.allow)
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
		if let pageTitle = webView.title {
			var title = pageTitle;
			if title.isEmpty { title = "HeliumLift" }
			let notif = Notification(name: Notification.Name("HeliumUpdateTitle"), object: title);
			NotificationCenter.default.post(notif)
		}
	}

	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		NSLog("\(error.localizedDescription)")
	}

	// MARK: -
	// MARK: URL Rewriting

	private func rewriteURL(_ url: URL) -> URL?
	{
		// parse the url components
		guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
			return nil
		}

		// rewrite urls by host
		switch components.host {
			case "dai.ly", "dailymotion.com", "www.dailymotion.com":
				// rewrite dailymotion links
				components = rewriteDailymotionLinks(components)
			case "vimeo.com", "www.vimeo.com", "player.vimeo.com":
				// rewrite vimeo links
				components = rewriteVimeoLinks(components)
			case "youku.com", "v.youku.com", "player.youku.com":
				// rewrite youku links
				components = rewriteYoukuLinks(components)
			case "youtu.be", "youtube.com", "www.youtube.com":
				// rewrite youtube links
				components = rewriteYouTubeLinks(components)
			default:
				break
		}

		// get the rewritten url
		guard let rewrittenURL = components.url else {
			return nil
		}

		// check if the url is the same
		if url.absoluteString == rewrittenURL.absoluteString {
			return nil
		}

		return rewrittenURL
	}

	private func rewriteDailymotionLinks(_ urlComponents: URLComponents) -> URLComponents
	{
		var components = urlComponents
		var videoID: Substring?

		// set dailymotion links to use https
		components.scheme = "https"

		// extract the video id
		if components.path.hasPrefix("/video/") {
			// (ex. https://www.dailymotion.com/video/x7mj6ld)
			let index = components.path.index(components.path.startIndex, offsetBy: 7)
			videoID = components.path[index...]
		} else if components.path.hasPrefix("/embed/video/") {
			// (ex. https://www.dailymotion.com/embed/video/x7mj6ld)
			let index = components.path.index(components.path.startIndex, offsetBy: 13)
			videoID = components.path[index...]
		} else if components.host == "dai.ly" {
			// (ex. https://dai.ly/x7mj6ld)
			let index = components.path.index(components.path.startIndex, offsetBy: 1)
			videoID = components.path[index...]
		}

		// convert to an embedded link
		// (ex. https://www.dailymotion.com/embed/video/x7mj6ld)

		if let videoID = videoID {
			components.host = "www.dailymotion.com"
			components.path = "/embed/video/\(videoID)"
		}

		return components
	}

	private func rewriteVimeoLinks(_ urlComponents: URLComponents) -> URLComponents
	{
		var components = urlComponents
		var videoID: Substring?

		// set vimeo links to use https
		components.scheme = "https"

		// extract the video id
		if ((components.host == "vimeo.com") || (components.host == "www.vimeo.com")) && components.path.hasPrefix("/") {
			// (ex. https://vimeo.com/364433394)
			let index = components.path.index(components.path.startIndex, offsetBy: 1)
			videoID = components.path[index...]
		} else if (components.host == "player.vimeo.com") && components.path.hasPrefix("/video/") {
			// (ex. https://player.vimeo.com/video/364433394)
			let index = components.path.index(components.path.startIndex, offsetBy: 7)
			videoID = components.path[index...]
		}

		// check we have a video id made of only numbers
		if let videoID = videoID, videoID.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil {
			// convert to an embedded link
			// (ex. https://player.vimeo.com/video/364433394)
			components.host = "player.vimeo.com"
			components.path = "/video/\(videoID)"
		}

		return components
	}

	private func rewriteYoukuLinks(_ urlComponents: URLComponents) -> URLComponents
	{
		var components = urlComponents
		var videoID: Substring?

		// extract the video id
		// (ex. https://v.youku.com/v_show/id_XMzU3MTY5OTQ4MA==.html)

		if components.host == "v.youku.com" {
			if let start = components.path.range(of: "id_"), let end = components.path.range(of: "=="), (start.upperBound < end.lowerBound) {
				videoID = components.path[start.upperBound ..< end.lowerBound]
			}
		}

		// convert to an embedded link
		// (ex. http://player.youku.com/embed/XMzU3Mzk2OTc2NA)

		if let videoID = videoID {
			components.scheme = "http"
			components.host = "player.youku.com"
			components.path = "/embed/\(videoID)"
			components.queryItems = nil
		}

		return components
	}

	private func rewriteYouTubeLinks(_ urlComponents: URLComponents) -> URLComponents
	{
		var components = urlComponents
		var queryItems = components.queryItems ?? [URLQueryItem]()
		var videoID: String?

		// parse the video id from youtube urls
		if components.host!.hasSuffix("youtu.be") {
			// youtu.be links put the video id in the path
			// (ex. https://youtu.be/kqpak5lFxvs)
			let idIndex = components.path.index(components.path.startIndex, offsetBy: 1)
			videoID = String(components.path[idIndex...])
		} else if components.path.hasPrefix("/embed/") {
			// embed links contain the video id in the path
			// (ex. https://www.youtube.com/embed/kqpak5lFxvs)
			let idIndex = components.path.index(components.path.startIndex, offsetBy: 7)
			videoID = String(components.path[idIndex...])
		} else if components.path.hasPrefix("/v/") {
			// video links contain the video id in the path
			// (ex. https://www.youtube.com/v/kqpak5lFxvs)
			let idIndex = components.path.index(components.path.startIndex, offsetBy: 3)
			videoID = String(components.path[idIndex...])
		} else {
			// check the query items for the video id
			// (ex. https://www.youtube.com/watch?v=kqpak5lFxvs)
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

		// rewrite links that contain a valid video id
		// (ex. https://www.youtube.com/embed/kqpak5lFxvs)

		if let videoID = videoID, (videoID.count == 11) {
			// make sure that autoplay is set
			components.host = "www.youtube.com"
			queryItems.removeAll(where: { $0.name == "autoplay" })
			queryItems.append(URLQueryItem(name: "autoplay", value: "1"))
			// rewrite links to use embedded likns
			components.path = "/embed/\(videoID)"
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

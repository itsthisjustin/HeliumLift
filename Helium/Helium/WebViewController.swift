//
//  ViewController.swift
//  Helium Lift
//
//  Modified by Justin Mitchell on 7/12/15.
//  Copyright (c) 2015 Justin Mitchell. All rights reserved.
//

import Cocoa
import WebKit

class WebViewController: NSViewController, WKNavigationDelegate {
    
    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addTrackingRect(view.bounds, owner: self, userData: nil, assumeInside: false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(WebViewController.loadURLObject(_:)), name: NSNotification.Name(rawValue: "HeliumLoadURL"), object: nil)
        
        // Layout webview
        view.addSubview(webView)
        webView.frame = view.bounds
        webView.autoresizingMask = [NSView.AutoresizingMask.height, NSView.AutoresizingMask.width]
        webView.configuration.preferences.javaScriptEnabled = true
        webView.configuration.preferences.javaEnabled = true
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        // Allow plug-ins such as silverlight
        webView.configuration.preferences.plugInsEnabled = true
        
        // Custom user agent string for Netflix HTML5 support
        webView._customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/601.6.17 (KHTML, like Gecko) Version/9.1.1 Safari/601.6.17"

        // Setup magic URLs
        webView.navigationDelegate = self
        webView.uiDelegate = self as! WKUIDelegate
    
        // Allow zooming
        webView.allowsMagnification = true
        
        // Allow back and forth
        webView.allowsBackForwardNavigationGestures = true
        
        // Listen for load progress
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: NSKeyValueObservingOptions.new, context: nil)
    
        clear()
    }
    
    // MARK: Actions
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool{
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
    
    func loadURL(_ url:URL) {
        webView.load(URLRequest(url: url))
    }
    
    //MARK: - loadURLObject
    @objc func loadURLObject(_ urlObject : Notification) {
        
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
            //loadURL(URL(string: "http://heliumlift.duet.to/start.html")!)
            loadURL(URL(string: "http://heliumlift.bitballoon.com")!)
        }
    }
    
    let webView = WKWebView()
    var shouldRedirect: Bool {
        get {
            return !UserDefaults.standard.bool(forKey: UserSetting.disabledMagicURLs.userDefaultsKey)
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if let saveError = error as? NSError {
            NSLog("%@", saveError)
        }
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        
    }
    
    // Redirect Hulu and YouTube to pop-out videos
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if shouldRedirect, let url = navigationAction.request.url {
            let urlString = url.absoluteString
            var modified = urlString
            
            // Change desktop youtube to youtube tv to enable fullscreen mode
            if modified == "https://www.youtube.com/" {
                modified = "https://www.youtube.com/tv#"
            }
            
            // To change the url to make the video fullscreen. The problem is that when click on a video in
            // youtube homepage, the url doesn't return the normal youtube video url. It just returns about:blank
            // and some weird google url. Solution follows...
            
            //  Change everything to YouTube TV
            modified = modified.replacePrefix("https://www.youtube.com/watch?v=", replacement: "https://www.youtube.com/tv#/watch?v=")
            modified = modified.replacePrefix("https://vimeo.com/", replacement: "http://player.vimeo.com/video/")
            modified = modified.replacePrefix("http://v.youku.com/v_show/id_", replacement: "http://player.youku.com/embed/")
            modified = modified.replacePrefix("https://www.twitch.tv/", replacement: "https://player.twitch.tv?html5&channel=")
            modified = modified.replacePrefix("http://www.dailymotion.com/video/", replacement: "http://www.dailymotion.com/embed/video/")
            modified = modified.replacePrefix("http://dai.ly/", replacement: "http://www.dailymotion.com/embed/video/")
            
            if modified.contains("https://youtu.be") {
                modified = "https://www.youtube.com/tv#/watch?v=" + getVideoHash(urlString)
                if urlString.contains("?t=") {
                    modified += makeCustomStartTimeURL(urlString)
                }
            }
            
            // To make embed youtube video autoplay
//            if modified.hasPrefix("https://www.youtube.com/embed/") {
//                if !modified.containsString("?autoplay=1") {
//                    modified += "?autoplay=1"
//                }
//            }
            
            if urlString != modified {
                decisionHandler(WKNavigationActionPolicy.cancel)
                loadURL(URL(string: modified)!)
                return
            }
            
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
        if let saveError = error as? NSError {
            NSLog("%@", saveError)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        //change?["new"]
        if object as! NSObject == webView && keyPath == "estimatedProgress" {
            if let changeValueKeyPair = change {
            if let progress: Float = changeValueKeyPair[NSKeyValueChangeKey(rawValue: "new")] as? Float! {
                let percent = progress * 100
                var title = NSString(format: "Loading... %.2f%%", percent)
                if percent == 100 {
                    title = "HeliumLift"
                }
                
                let notif = Notification(name: Notification.Name(rawValue: "HeliumUpdateTitle"), object: title);
                NotificationCenter.default.post(notif)
            }
            }
        }
        
        
    }
    
    //Convert a YouTube video url that starts at a certian point to popup/embedded design
    // (i.e. ...?t=1m2s --> ?start=62)
    fileprivate func makeCustomStartTimeURL(_ url: String) -> String {
        let startTime = "?t="
        let idx = url.indexOf(startTime)
        if idx == -1 {
            return url
        } else {
            var returnURL = url
            let timing = url.substring(from: url.characters.index(url.startIndex, offsetBy: idx+3))
            let hoursDigits = timing.indexOf("h")
            var minutesDigits = timing.indexOf("m")
            let secondsDigits = timing.indexOf("s")
            
            returnURL.removeSubrange(returnURL.characters.index(returnURL.startIndex, offsetBy: idx+1) ..< returnURL.endIndex)
            returnURL = "?start="
            
            //If there are no h/m/s params and only seconds (i.e. ...?t=89)
            if (hoursDigits == -1 && minutesDigits == -1 && secondsDigits == -1) {
                let onlySeconds = url.substring(from: url.characters.index(url.startIndex, offsetBy: idx+3))
                returnURL = returnURL + onlySeconds
                return returnURL
            }
            
            //Do check to see if there is an hours parameter.
            var hours = 0
            if (hoursDigits != -1) {
                hours = Int(timing.substring(to: timing.characters.index(timing.startIndex, offsetBy: hoursDigits)))!
            }
            
            //Do check to see if there is a minutes parameter.
            var minutes = 0
            if (minutesDigits != -1) {
                minutes = Int(timing.substring(with: timing.characters.index(timing.startIndex, offsetBy: hoursDigits+1) ..< timing.characters.index(timing.startIndex, offsetBy: minutesDigits)))!
            }
            
            if minutesDigits == -1 {
                minutesDigits = hoursDigits
            }
            
            //Do check to see if there is a seconds parameter.
            var seconds = 0
            if (secondsDigits != -1) {
                seconds = Int(timing.substring(with: timing.characters.index(timing.startIndex, offsetBy: minutesDigits+1) ..< timing.characters.index(timing.startIndex, offsetBy: secondsDigits)))!
            }
            
            //Combine all to make seconds.
            let secondsFinal = 3600*hours + 60*minutes + seconds
            returnURL = returnURL + String(secondsFinal)
            
            return returnURL
        }
    }
    
    //Helper function to return the hash of the video for encoding a popout video that has a start time code.
    fileprivate func getVideoHash(_ url: String) -> String {
        let startOfHash = url.indexOf(".be/")
        let endOfHash = url.indexOf("?t")
        let hash = url.substring(with: url.characters.index(url.startIndex, offsetBy: startOfHash+4) ..<
            (endOfHash == -1 ? url.endIndex : url.characters.index(url.startIndex, offsetBy: endOfHash)))
        return hash
    }

}

extension String {
    func replacePrefix(_ prefix: String, replacement: String) -> String {
        if hasPrefix(prefix) {
            return replacement + substring(from: prefix.endIndex)
        }
        else {
            return self
        }
        
    }
    
    func indexOf(_ target: String) -> Int {
        let range = self.range(of: target)
        if let range = range {
            return self.characters.distance(from: self.startIndex, to: range.lowerBound)
        } else {
            return -1
        }
    }
}

extension WebViewController: WKUIDelegate {

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        webView.url
        webView.load(navigationAction.request)
        
        return nil;
    }
    
}

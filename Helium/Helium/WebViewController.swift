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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addTrackingRect(view.bounds, owner: self, userData: nil, assumeInside: false)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WebViewController.loadURLObject(_:)), name: "HeliumLoadURL", object: nil)
        
        // Layout webview
        view.addSubview(webView)
        webView.frame = view.bounds
        webView.autoresizingMask = [NSAutoresizingMaskOptions.ViewHeightSizable, NSAutoresizingMaskOptions.ViewWidthSizable]
        
        
        // Allow plug-ins such as silverlight
        webView.configuration.preferences.plugInsEnabled = true
        
        // Custom user agent string for Netflix HTML5 support
        webView._customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/601.6.17 (KHTML, like Gecko) Version/9.1.2 Safari/601.6.17"

        
        // Setup magic URLs
        webView.navigationDelegate = self
        
        // Allow zooming
        webView.allowsMagnification = true
        
        // Allow back and forth
        webView.allowsBackForwardNavigationGestures = true
        
        // Listen for load progress
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: NSKeyValueObservingOptions.New, context: nil)
        
        clear()
    }
    
    // MARK: Actions
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool{
        switch menuItem.title {
        case "Back":
            return webView.canGoBack
        case "Forward":
            return webView.canGoForward
        default:
            return true
        }
    }
    
    @IBAction func backPress(sender: AnyObject) {
        webView.goBack()
    }
    
    @IBAction func forwardPress(sender: AnyObject) {
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
    
    @IBAction func reloadPress(sender: AnyObject) {
        requestedReload()
    }
    
    @IBAction func clearPress(sender: AnyObject) {
        clear()
    }
    
    @IBAction func resetZoomLevel(sender: AnyObject) {
        resetZoom()
    }
    @IBAction func zoomIn(sender: AnyObject) {
        zoomIn()
    }
    @IBAction func zoomOut(sender: AnyObject) {
        zoomOut()
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    internal func loadAlmostURL(text: String) {
        var text = text
        if !(text.lowercaseString.hasPrefix("http://") || text.lowercaseString.hasPrefix("https://")) {
            text = "http://" + text
        }
        
        if let url = NSURL(string: text) {
            loadURL(url)
        }
    }
    
    // MARK: Loading
    
    func loadURL(url:NSURL) {
        webView.loadRequest(NSURLRequest(URL: url))
    }
    
    //MARK: - loadURLObject
    func loadURLObject(urlObject : NSNotification) {
        
        // This is where the work gets done - it grabs everything after
        // "openURL=" from the urlObject, makes a new NSURL out of it
        // and sends it to loadURL.
        
//        if let url = urlObject.object as? NSURL,
//            let lastPart = url.absoluteString.componentsSeparatedByString("openURL=").last,
//            let newURL = NSURL(string: lastPart) {
//                loadURL(newURL);
//        }
        
        if let url = urlObject.object as? NSURL {
            loadAlmostURL(url.absoluteString)
        }
    }
    
    func requestedReload() {
        webView.reload()
    }
    
    // MARK: Webview functions
    
    // Keep the URL the same
    func clear() {
        if let homePage = NSUserDefaults.standardUserDefaults().stringForKey(UserSetting.HomePageURL.userDefaultsKey) {
            loadAlmostURL(homePage)
        } else {
            loadURL(NSURL(string: "http://heliumlift.duet.to/start.html")!)
        }
    }
    
    let webView = WKWebView()
    var shouldRedirect: Bool {
        get {
            return !NSUserDefaults.standardUserDefaults().boolForKey(UserSetting.DisabledMagicURLs.userDefaultsKey)
        }
    }
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        NSLog("%@", error)
    }
    
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
    }
    
    // Redirect Hulu and YouTube to pop-out videos
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        if shouldRedirect, let url = navigationAction.request.URL {
            
            let urlString = url.absoluteString
            var modified = urlString
            modified = modified.replacePrefix("https://www.youtube.com/watch?v=", replacement: modified.containsString("list") ? "https://www.youtube.com/embed/?v=" : "https://www.youtube.com/embed/")
            modified = modified.replacePrefix("https://vimeo.com/", replacement: "http://player.vimeo.com/video/")
            modified = modified.replacePrefix("http://v.youku.com/v_show/id_", replacement: "http://player.youku.com/embed/")
            modified = modified.replacePrefix("https://www.twitch.tv/", replacement: "https://player.twitch.tv?html5&channel=")
            modified = modified.replacePrefix("http://www.dailymotion.com/video/", replacement: "http://www.dailymotion.com/embed/video/")
            modified = modified.replacePrefix("http://dai.ly/", replacement: "http://www.dailymotion.com/embed/video/")
            
            if modified.containsString("https://youtu.be") {
                modified = "https://www.youtube.com/embed/" + getVideoHash(urlString)
                if urlString.containsString("?t=") {
                    modified += makeCustomStartTimeURL(urlString)
                }
            }
            
            if urlString != modified {
                decisionHandler(WKNavigationActionPolicy.Cancel)
                loadURL(NSURL(string: modified)!)
                return
            }
        }
        
        decisionHandler(WKNavigationActionPolicy.Allow)

    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation) {
        if let pageTitle = webView.title {
            var title = pageTitle;
            if title.isEmpty { title = "HeliumLift" }
            let notif = NSNotification(name: "HeliumUpdateTitle", object: title);
            NSNotificationCenter.defaultCenter().postNotification(notif)
        }
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        NSLog("%@", error)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if object as! NSObject == webView && keyPath == "estimatedProgress" {
            if let progress = change?["new"] as? Float {
                let percent = progress * 100
                var title = NSString(format: "Loading... %.2f%%", percent)
                if percent == 100 {
                    title = "HeliumLift"
                }
                
                let notif = NSNotification(name: "HeliumUpdateTitle", object: title);
                NSNotificationCenter.defaultCenter().postNotification(notif)
            }
        }
        
        
    }
    
    //Convert a YouTube video url that starts at a certian point to popup/embedded design
    // (i.e. ...?t=1m2s --> ?start=62)
    private func makeCustomStartTimeURL(url: String) -> String {
        let startTime = "?t="
        let idx = url.indexOf(startTime)
        if idx == -1 {
            return url
        } else {
            var returnURL = url
            let timing = url.substringFromIndex(url.startIndex.advancedBy(idx+3))
            let hoursDigits = timing.indexOf("h")
            var minutesDigits = timing.indexOf("m")
            let secondsDigits = timing.indexOf("s")
            
            returnURL.removeRange(returnURL.startIndex.advancedBy(idx+1) ..< returnURL.endIndex)
            returnURL = "?start="
            
            //If there are no h/m/s params and only seconds (i.e. ...?t=89)
            if (hoursDigits == -1 && minutesDigits == -1 && secondsDigits == -1) {
                let onlySeconds = url.substringFromIndex(url.startIndex.advancedBy(idx+3))
                returnURL = returnURL + onlySeconds
                return returnURL
            }
            
            //Do check to see if there is an hours parameter.
            var hours = 0
            if (hoursDigits != -1) {
                hours = Int(timing.substringToIndex(timing.startIndex.advancedBy(hoursDigits)))!
            }
            
            //Do check to see if there is a minutes parameter.
            var minutes = 0
            if (minutesDigits != -1) {
                minutes = Int(timing.substringWithRange(timing.startIndex.advancedBy(hoursDigits+1) ..< timing.startIndex.advancedBy(minutesDigits)))!
            }
            
            if minutesDigits == -1 {
                minutesDigits = hoursDigits
            }
            
            //Do check to see if there is a seconds parameter.
            var seconds = 0
            if (secondsDigits != -1) {
                seconds = Int(timing.substringWithRange(timing.startIndex.advancedBy(minutesDigits+1) ..< timing.startIndex.advancedBy(secondsDigits)))!
            }
            
            //Combine all to make seconds.
            let secondsFinal = 3600*hours + 60*minutes + seconds
            returnURL = returnURL + String(secondsFinal)
            
            return returnURL
        }
    }
    
    //Helper function to return the hash of the video for encoding a popout video that has a start time code.
    private func getVideoHash(url: String) -> String {
        let startOfHash = url.indexOf(".be/")
        let endOfHash = url.indexOf("?t")
        let hash = url.substringWithRange(url.startIndex.advancedBy(startOfHash+4) ..<
            (endOfHash == -1 ? url.endIndex : url.startIndex.advancedBy(endOfHash)))
        return hash
    }

}

extension String {
    func replacePrefix(prefix: String, replacement: String) -> String {
        if hasPrefix(prefix) {
            return replacement + substringFromIndex(prefix.endIndex)
        }
        else {
            return self
        }
        
    }
    
    func indexOf(target: String) -> Int {
        let range = self.rangeOfString(target)
        if let range = range {
            return self.startIndex.distanceTo(range.startIndex)
        } else {
            return -1
        }
    }
}

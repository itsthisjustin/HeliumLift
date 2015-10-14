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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadURLObject:", name: "HeliumLoadURL", object: nil)
        
        // Layout webview
        webView.frame = view.bounds
        
        view.addSubview(webView)
        
        view.addSubview(webView)
        
        webView.frame = view.bounds
        
        webView.autoresizingMask = [NSAutoresizingMaskOptions.ViewHeightSizable, NSAutoresizingMaskOptions.ViewWidthSizable]
        
        
        
        // Allow plug-ins such as silverlight
        
        webView.configuration.preferences.plugInsEnabled = true
        
        
        
        // Custom user agent string for Netflix HTML5 support
        
        webView._customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_4) AppleWebKit/600.7.12 (KHTML, like Gecko) Version/8.0.7 Safari/600.7.12"

        
        // Setup magic URLs
        webView.navigationDelegate = self
        
        // Allow zooming
        webView.allowsMagnification = true
        
        // Listen for load progress
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: NSKeyValueObservingOptions.New, context: nil)
        
        clear()
    }
    
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
    
    func loadURL(url:NSURL) {
        webView.loadRequest(NSURLRequest(URL: url))
    }
    
    //MARK: - loadURLObject
    func loadURLObject(urlObject : NSNotification) {
        
        // This is where the work gets done - it grabs everything after
        // "openURL=" from the urlObject, makes a new NSURL out of it
        // and sends it to loadURL.
        
        if let url = urlObject.object as? NSURL,
            let lastPart = url.absoluteString.componentsSeparatedByString("openURL=").last,
            let newURL = NSURL(string: lastPart) {
                loadURL(newURL);
        }
    }
    
    func requestedReload() {
        webView.reload()
    }
    
    func clear() {
        loadURL(NSURL(string: "http://heliumlift.duet.to/start.html")!)
    }
    
    var webView = WKWebView()
    var shouldRedirect: Bool {
        get {
            return !NSUserDefaults.standardUserDefaults().boolForKey("disabledMagicURLs")
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
        
        if shouldRedirect {
            let URL = navigationAction.request.URL
            
            if URL != nil {
                let URLString = URL!.absoluteString
                
                let modifiedURLString = URLString
                    .replacePrefix("https://www.youtube.com/watch?", replacement: "https://www.youtube.com/watch_popup?")
                    .replacePrefix("https://vimeo.com/", replacement: "http://player.vimeo.com/video/")
                    .replacePrefix("http://v.youku.com/v_show/id_", replacement: "http://player.youku.com/embed/")
                
                if URLString != modifiedURLString {
                    decisionHandler(WKNavigationActionPolicy.Cancel)
                    loadURL(NSURL(string: modifiedURLString)!)
                    return
                }
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
            let progress: AnyObject? = change?["new"]
            
            if progress is Float {
                let percent = (progress as! Float) * 100.0
                var title = NSString(format: "Loading... %.2f%%", percent)
                if percent == 100 {
                    title = "Helium Lift"
                }
                
                let notif = NSNotification(name: "HeliumUpdateTitle", object: title);
                NSNotificationCenter.defaultCenter().postNotification(notif)
            }
        }
        
        
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
}

//
//  Application.swift
//  HeliumLift
//
//  Created by Niall on 03/09/2015.
//  Copyright © 2015-2019 Justin Mitchell. All rights reserved.
//

import Cocoa

@objc(Application)
class Application: NSApplication {
    override func sendEvent(_ event: NSEvent) {
        if event.type == NSEvent.EventType.keyDown {
            if (event.modifierFlags.intersection(NSEvent.ModifierFlags.deviceIndependentFlagsMask) == NSEvent.ModifierFlags.command) {
                
                let nController = ((NSApplication.shared.windows.first! as NSWindow).contentViewController as! WebViewController)
                
                let appDelegate = NSApplication.shared.delegate as! AppDelegate
                
                //switch event.charactersIgnoringModifiers!.lowercaseString {
                switch event.keyCode {
                case 0: // a
                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) { return }
                case 2: // d
                    appDelegate.webViewController.clear()
                case 6: // z
                   // if NSApp.sendAction(#selector(NSText.un?(nController.webView).undo()), to:nil, from:self) { return }
                    //if NSApp.sendAction(#selector(NSText.undoManager?.undo()), to:nil, from:self) { return }
                    return
                case 7: // x
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return }
                case 8: // c
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return }
                case 9: // v
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return }
                case 12: // q
                    NSApplication.shared.terminate(self)
                case 16: // y
                    let nWindow = (NSApplication.shared.windows.first! as NSWindow)
                    if (nWindow.isVisible) { nWindow.setIsVisible(false); return }
                    else { nWindow.setIsVisible(true); return }
                case 17: // t
                    if appDelegate.translucent {
                        appDelegate.didDisableTranslucency()
                    } else {
                        appDelegate.didEnableTranslucency()
                    }
                    return
                case 24: // +
                    nController.zoomIn()
                    return
                case 27: // -
                    nController.zoomOut()
                    return
                case 30: // ]
                    nController.webView.goForward()
                    return
                case 33: // [
                    nController.webView.goBack()
                    return
                case 37: // l
                    appDelegate.didRequestLocation()
                    return
                default:
                    break
                
                }
            }
            else if (event.modifierFlags.intersection(NSEvent.ModifierFlags.deviceIndependentFlagsMask) == (NSEvent.ModifierFlags.command.union(NSEvent.ModifierFlags.shift))) {
                if event.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(Selector(("redo:")), to:nil, from:self) { return }
                }
            }
        }
        return super.sendEvent(event)
    }
}

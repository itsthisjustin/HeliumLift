//
//  Application.swift
//  HeliumLift
//
//  Created by Niall on 03/09/2015.
//  Copyright (c) 2015 Justin Mitchell. All rights reserved.
//

import Cocoa

@objc(Application)
class Application: NSApplication {
    override func sendEvent(event: NSEvent) {
        if event.type == NSEventType.KeyDown {
            if (event.modifierFlags.intersect(NSEventModifierFlags.DeviceIndependentModifierFlagsMask) == NSEventModifierFlags.CommandKeyMask) {
                
                let nController = ((NSApplication.sharedApplication().windows.first! as NSWindow).contentViewController as! WebViewController)
                
                //switch event.charactersIgnoringModifiers!.lowercaseString {
                switch event.keyCode {
                case 0: // a
                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) { return }
                case 6: // z
                    if NSApp.sendAction(#selector(NSText.undoManagerForWebView(_:)), to:nil, from:self) { return }
                case 7: // x
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return }
                case 8: // c
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return }
                case 9: // v
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return }
                case 12: // q
                    NSApplication.sharedApplication().terminate(self)
                case 16: // y
                    let nWindow = (NSApplication.sharedApplication().windows.first! as NSWindow)
                    if (nWindow.visible) { nWindow.setIsVisible(false); return }
                    else { nWindow.setIsVisible(true); return }
                case 17: // t
                    let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
                    if(appDelegate.translucent) { appDelegate.didDisableTranslucency() }
                    else { appDelegate.didEnableTranslucency(); }
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
                    (NSApplication.sharedApplication().delegate as! AppDelegate).didRequestLocation()
                    return
                default:
                    break
                
                }
            }
            else if (event.modifierFlags.intersect(NSEventModifierFlags.DeviceIndependentModifierFlagsMask) == (NSEventModifierFlags.CommandKeyMask.union(NSEventModifierFlags.ShiftKeyMask))) {
                if event.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(Selector("redo:"), to:nil, from:self) { return }
                }
            }
        }
        return super.sendEvent(event)
    }
}
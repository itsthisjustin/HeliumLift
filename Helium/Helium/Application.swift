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
                switch event.charactersIgnoringModifiers!.lowercaseString {
                case "x":
                    if NSApp.sendAction(Selector("cut:"), to:nil, from:self) { return }
                case "c":
                    if NSApp.sendAction(Selector("copy:"), to:nil, from:self) { return }
                case "v":
                    if NSApp.sendAction(Selector("paste:"), to:nil, from:self) { return }
                case "z":
                    if NSApp.sendAction(Selector("undo:"), to:nil, from:self) { return }
                case "a":
                    if NSApp.sendAction(Selector("selectAll:"), to:nil, from:self) { return }
                case "q":
                    NSApplication.sharedApplication().terminate(self)
                case "t":
                    let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
                    if(appDelegate.translucent) { appDelegate.didDisableTranslucency() }
                    else { appDelegate.didEnableTranslucency(); }
                    return
                case "y":
                    let nWindow = (NSApplication.sharedApplication().windows.first! as NSWindow)
                    if (nWindow.visible) { nWindow.setIsVisible(false); return }
                    else { nWindow.setIsVisible(true); return }
                default:
                    let nController = ((NSApplication.sharedApplication().windows.first! as NSWindow).contentViewController as! WebViewController)
                    switch(event.keyCode) {
                    case 24: // '+'
                        nController.zoomIn()
                        return
                    case 27: // '-'
                        nController.zoomOut()
                        return
                    case 30: // ']'
                        nController.webView.goForward()
                        return
                    case 33: // '['
                        nController.webView.goBack()
                        return
                    default:
                        break
                    }
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
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
            if (event.modifierFlags & NSEventModifierFlags.DeviceIndependentModifierFlagsMask == NSEventModifierFlags.CommandKeyMask) {
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
                default:
                    break
                }
            }
            else if (event.modifierFlags & NSEventModifierFlags.DeviceIndependentModifierFlagsMask == (NSEventModifierFlags.CommandKeyMask | NSEventModifierFlags.ShiftKeyMask)) {
                if event.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(Selector("redo:"), to:nil, from:self) { return }
                }
            }
        }
        return super.sendEvent(event)
    }
}
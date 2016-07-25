//
//  UserSettings.swift
//  HeliumLift
//
//  Created by Zack V. Apiratitham on 7/25/16.
//  Copyright © 2016 Justin Mitchell. All rights reserved.
//

import Foundation

internal enum UserSetting {
    case DisabledMagicURLs
    case DisabledFullScreenFloat
    case OpacityPercentage
    case HomePageURL
    
    var userDefaultsKey: String {
        switch self {
        case .DisabledMagicURLs: return "disabledMagicURLs"
        case .DisabledFullScreenFloat: return "disabledFullScreenFloat"
        case .OpacityPercentage: return "opacityPercentage"
        case .HomePageURL: return "homePageURL"
        }
    }
}

//
//  UserSettings.swift
//  HeliumLift
//
//  Created by Zack V. Apiratitham on 7/25/16.
//  Copyright © 2016 Justin Mitchell. All rights reserved.
//

import Foundation

internal enum UserSetting {
    case disabledMagicURLs
    case disabledFullScreenFloat
    case opacityPercentage
    case homePageURL
    
    var userDefaultsKey: String {
        switch self {
        case .disabledMagicURLs: return "disabledMagicURLs"
        case .disabledFullScreenFloat: return "disabledFullScreenFloat"
        case .opacityPercentage: return "opacityPercentage"
        case .homePageURL: return "homePageURL"
        }
    }
}

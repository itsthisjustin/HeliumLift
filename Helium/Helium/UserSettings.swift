//
//  UserSettings.swift
//  HeliumLift
//
//  Created by Zack V. Apiratitham on 7/25/16.
//  Copyright © 2016-2019 Justin Mitchell. All rights reserved.
//

import Foundation

internal enum UserSetting {

	case disabledMagicURLs
	case opacityPercentage
	case homePageURL

	var userDefaultsKey: String {
		switch self {
		case .disabledMagicURLs: return "disabledMagicURLs"
		case .opacityPercentage: return "opacityPercentage"
		case .homePageURL: return "homePageURL"
		}
	}

}

//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

let CELL_PADDING_HORIZONTAL = CGFloat(12)
let CELL_PADDING_VERTICAL	= CGFloat(12)
let CELL_VIEW_SPACING		= CGFloat(8)

let CELL_CONTEXT_HEIGHT		= CGFloat(20)
let CELL_HEADER_HEIGHT		= CGFloat(20)
let CELL_FOOTER_HEIGHT		= CGFloat(20)

let CELL_USER_PHOTO_SIZE	= CGFloat(48)
let CELL_PHOTO_RATIO		= CGFloat(0.56)	// 16:9 aspect ratio
let SPACER_WIDTH: CGFloat   = 12

/* Theming */

let Theme = Snow()

class Snow {
	
	let light					= true
	
	let colorText				= Colors.black
	let colorTextSecondary		= Colors.gray50pcntColor
	let colorTextDisplay		= Colors.black
	let colorTextTitle			= Colors.accentOnLight
	let colorTextBanner			= Colors.white
	let colorTextPlaceholder	= Colors.lightGray
	let colorTextNotification	= Colors.white
	let colorTextToast			= Colors.black
	let colorTextActivity		= Colors.black
	let colorNumberFeatured		= Colors.accentColorDark

	let colorBackgroundForm         = Colors.white
	let colorBackgroundTable		= Colors.gray95pcntColor
	let colorBackgroundWindow       = Colors.gray90pcntColor
	let colorBackgroundImage        = Colors.gray90pcntColor
	let colorBackgroundNotification = Colors.brandColor
	let colorBackgroundSidebar      = Colors.white
	let colorBackgroundTile         = Colors.white
	let colorBackgroundTileList     = Colors.gray95pcntColor
	let colorBackgroundToast        = Colors.accentColorFill
	let colorBackgroundOverlay      = Colors.opacity75pcntBlack
	let colorBackgroundActivity     = Colors.white
	let colorBackgroundActivityOnly = Colors.clear
	let colorBackgroundEmptyBubble  = Colors.gray97pcntColor
	let colorBackgroundAgeDot       = Colors.accentColorFill
	let colorBackgroundContactSelected 	= Colors.accentColorFill
	let colorBackgroundSelected		= Colors.gray90pcntColor

	let colorRule                   = Colors.gray75pcntColor
	let colorRuleActive             = Colors.accentColorRule
	let colorTint                   = Colors.brandColorTextLight
	let colorTabBarTint             = Colors.brandColorTextLight
	let colorShadow					= Colors.gray80pcntColor
	let colorSeparator				= Colors.gray90pcntColor
	let colorScrimInvite            = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.15))
	let colorScrimDarken            = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.3))
	let colorScrimLighten           = UIColor(red: CGFloat(1), green: CGFloat(1), blue: CGFloat(1), alpha: CGFloat(0.75))
	let colorActionOn               = Colors.brandColorTextDark
	let colorActionOff              = Colors.brandColorTextDark
	let colorActivityIndicator      = Colors.brandColor
	let colorActivityIndicatorImage = Colors.brandColor

	let colorButtonRadioTitle				= Colors.black
	let colorButtonRadioIcon				= Colors.black
	let colorButtonRadioIndicator			= Colors.brandColorTextLight
	
	let colorButtonTitle					= Colors.brandColorTextLight
	let colorButtonTitleFeatured			= Colors.white
	let colorButtonTitleHighlighted			= Colors.lightGray
	let colorButtonTitleFeaturedHighlighted = Colors.lightGray
	let colorButtonBorder					= Colors.gray66pcntColor
	let colorButtonBorderFeatured			= Colors.brandColorFill
	let colorButtonFill						= Colors.clear
	let colorButtonFillFeatured				= Colors.brandColorFill
	
	let fontSize				= 18

	let fontBanner				: UIFont! = UIFont(name: "HelveticaNeue-Thin", size: 48)
	let fontTitleLarge			: UIFont! = UIFont(name: "HelveticaNeue-Thin", size: 30)
	let fontTitle				: UIFont! = UIFont(name: "HelveticaNeue-Light", size: 22)
	let fontHeading				: UIFont! = UIFont(name: "HelveticaNeue-Light", size: 20)

	let fontText				: UIFont! = UIFont(name: "HelveticaNeue-Light", size: 18)
	let fontTextBold			: UIFont! = UIFont(name: "HelveticaNeue-Medium", size: 18)
	let fontTextDisplay			: UIFont! = UIFont(name: "HelveticaNeue-Light", size: 18)
	let fontTextList			: UIFont! = UIFont(name: "HelveticaNeue-Light", size: 17)
	let fontComment				: UIFont! = UIFont(name: "HelveticaNeue-Light", size: 16)
	let fontCommentSmall		: UIFont! = UIFont(name: "HelveticaNeue-Light", size: 14)
	let fontCommentExtraSmall	: UIFont! = UIFont(name: "HelveticaNeue-Light", size: 12)
	let fontButtonTitle			: UIFont! = UIFont(name: "HelveticaNeue", size: 16)
	let fontButtonRadioTitle	: UIFont! = UIFont(name: "HelveticaNeue-Light", size: 18)
	let fontLinkText			: UIFont! = UIFont(name: "HelveticaNeue", size: 18)
	let fontBarText				: UIFont! = UIFont(name: "HelveticaNeue", size: 18)
	let fontNumberFeatured		: UIFont! = UIFont(name: "HelveticaNeue-Light", size: 30)
	
	let colorLogVerbose			= Colors.gray50pcntColor
	let colorLogDebug			= Colors.accentColorDarker
	let colorLogInfo			= UIColor.purpleColor()
	let colorLogWarning			= UIColor.orangeColor()
	let colorLogError			= UIColor.redColor()
	
	let dimenButtonCornerRadius = 4
	let dimenButtonBorderWidth = CGFloat(0.5)
	let dimenRuleThickness = CGFloat(1.0)
}

public struct Colors {
	
	static let gray97pcntColor: UIColor = UIColor(red: CGFloat(0.97), green: CGFloat(0.97), blue: CGFloat(0.97), alpha: CGFloat(1))
	static let gray95pcntColor: UIColor = UIColor(red: CGFloat(0.95), green: CGFloat(0.95), blue: CGFloat(0.95), alpha: CGFloat(1))
	static let gray90pcntColor: UIColor = UIColor(red: CGFloat(0.9), green: CGFloat(0.9), blue: CGFloat(0.9), alpha: CGFloat(1))
	static let gray85pcntColor: UIColor = UIColor(red: CGFloat(0.85), green: CGFloat(0.85), blue: CGFloat(0.85), alpha: CGFloat(1))
	static let gray80pcntColor: UIColor = UIColor(red: CGFloat(0.8), green: CGFloat(0.8), blue: CGFloat(0.8), alpha: CGFloat(1))
	static let gray75pcntColor: UIColor = UIColor(red: CGFloat(0.75), green: CGFloat(0.75), blue: CGFloat(0.75), alpha: CGFloat(1))
	static let gray66pcntColor: UIColor = UIColor(red: CGFloat(0.667), green: CGFloat(0.667), blue: CGFloat(0.667), alpha: CGFloat(1)) // Light gray
	static let gray50pcntColor: UIColor = UIColor(red: CGFloat(0.5), green: CGFloat(0.5), blue: CGFloat(0.5), alpha: CGFloat(1)) // Light gray
	static let gray33pcntColor: UIColor = UIColor(red: CGFloat(0.33), green: CGFloat(0.33), blue: CGFloat(0.33), alpha: CGFloat(1)) // Dark gray
	
	static let opacity50pcntWhite: UIColor = UIColor(red: CGFloat(1), green: CGFloat(1), blue: CGFloat(1), alpha: CGFloat(0.5))
	static let opacity75pcntWhite: UIColor = UIColor(red: CGFloat(1), green: CGFloat(1), blue: CGFloat(1), alpha: CGFloat(0.75))
	static let opacity90pcntWhite: UIColor = UIColor(red: CGFloat(1), green: CGFloat(1), blue: CGFloat(1), alpha: CGFloat(0.90))

	static let opacity50pcntBlack: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.5))
	static let opacity75pcntBlack: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.75))
	static let opacity90pcntBlack: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.90))
	
	static let lightGray: UIColor = gray66pcntColor
	static let white: UIColor = UIColor.whiteColor()
	static let black: UIColor = UIColor.blackColor()
	static let clear: UIColor = UIColor.clearColor()
	
	static let brandColor = UIColor(hexString: "#FF7600FF")
	static let brandColorLight = UIColor(hexString: "#FF9439FF")
	static let brandColorLighter = UIColor(hexString: "#FFAB63FF")
	static let brandColorDark = UIColor(hexString: "#C55B00FF")
	static let brandColorDarker = UIColor(hexString: "#9B4800FF")
	
	static let accentColor = UIColor(hexString: "#69D3E7FF")
	static let accentColorLight = UIColor(hexString: "#95E4F3FF")
	static let accentColorLighter = UIColor(hexString: "#CDF5FCFF")
	static let accentColorDark = UIColor(hexString: "#44C0D7FF")
	static let accentColorDarker = UIColor(hexString: "#23A6BFFF")
	
	static let accentOnLight = accentColorDarker
	static let accentOnDark = accentColor
	static let brandOnLight = brandColor
	static let brandOnDark = brandColorLight
	
	static let accentColorTextLight = accentColorDarker
	static let accentColorTextDark = accentColor
	static let accentColorFill = accentColor
	static let accentColorRule = accentColor
	
	static let brandColorTextLight = brandColor
	static let brandColorTextDark = brandColor
	static let brandColorFill = brandColorLight
	static let brandColorRule = brandColor
	
	static let facebookColor = UIColor(hexString: "#3B5998ff")
	static let googleColor = UIColor(hexString: "#DD4B39ff")
}

//
//  UI.swift
//  Patchr
//
//  Created by Jay Massena on 5/9/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

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

protocol Theming {
	
	var colorText:				UIColor { get }
	var colorTextSecondary:		UIColor { get }
	var colorTextDisplay:		UIColor { get }
	var colorTextTitle:			UIColor { get }
	var colorTextBanner:		UIColor { get }
	var colorTextPlaceholder:	UIColor { get }
	var colorTextNotification:	UIColor { get }
	var colorTextToast:			UIColor { get }
	
	var colorBackgroundWindow:			UIColor { get }
	var colorBackgroundScreen:			UIColor { get }
	var colorBackgroundImage:			UIColor { get }
	var colorBackgroundTile:			UIColor { get }
	var colorBackgroundTileList:		UIColor { get }
	var colorBackgroundSidebar:			UIColor { get }
	var colorBackgroundToast:			UIColor { get }
	var colorBackgroundNotification:	UIColor { get }
	var colorBackgroundOverlay:			UIColor { get }
	
	var colorRule:				UIColor { get }
	var colorRuleActive:		UIColor { get }
	var colorTint:				UIColor { get }
	var colorScrimDarken:		UIColor { get }
	var colorScrimLighten:		UIColor { get }
	var colorActionOn:			UIColor { get }
	var colorActionOff:			UIColor { get }
	var colorActivity:			UIColor { get }
	var colorActivityImage:		UIColor { get }
	
	
	var colorButtonTitle:						UIColor { get }
	var colorButtonTitleFeatured:				UIColor { get }
	var colorButtonTitleHighlighted:			UIColor { get }
	var colorButtonTitleFeaturedHighlighted:	UIColor { get }
	var colorButtonBorder:						UIColor { get }
	var colorButtonBorderFeatured:				UIColor { get }
	var colorButtonFill:						UIColor { get }
	var colorButtonFillFeatured:				UIColor { get }
	
	var fontText:			UIFont { get }
	var fontTextDisplay:	UIFont { get }
	var fontTitle:			UIFont { get }
	var fontBanner:			UIFont { get }
	var fontComment:		UIFont { get }
	var fontButtonTitle:	UIFont { get }
	var fontLinkText:		UIFont { get }
	
	var dimenButtonCornerRadius:	Int { get }
	var dimenButtonBorderWidth:		CGFloat { get }
	var dimenRuleThickness:			CGFloat { get }
}

class Snow: Theming {
	
	let colorText				= Colors.black
	let colorTextSecondary		= Colors.gray50pcntColor
	let colorTextDisplay		= Colors.black
	let colorTextTitle			= Colors.accentColorDark
	let colorTextBanner			= Colors.accentColor
	let colorTextPlaceholder	= Colors.lightGray
	let colorTextNotification	= Colors.white
	let colorTextToast			= Colors.brandColorLight
	
	let colorBackgroundWindow		= Colors.gray90pcntColor
	let colorBackgroundImage		= Colors.gray90pcntColor
	let colorBackgroundNotification	= Colors.brandColor
	let colorBackgroundScreen		= Colors.white
	let colorBackgroundSidebar		= Colors.white
	let colorBackgroundTile			= Colors.white
	let colorBackgroundTileList		= Colors.gray90pcntColor
	let colorBackgroundToast		= Colors.brandColorLight
	let colorBackgroundOverlay		= Colors.opacity75pcntBlack
	
	let colorRule				= Colors.gray75pcntColor
	let colorRuleActive			= Colors.accentColor
	let colorTint				= Colors.brandColor
	let colorScrimDarken		= UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.3))
	let colorScrimLighten		= UIColor(red: CGFloat(1), green: CGFloat(1), blue: CGFloat(1), alpha: CGFloat(0.75))
	let colorActionOn			= Colors.brandColor
	let colorActionOff			= Colors.opacity90pcntWhite
	let colorActivity			= Colors.brandColor
	let colorActivityImage		= Colors.brandColor

	let colorButtonTitle					= Colors.brandColor
	let colorButtonTitleFeatured			= Colors.white
	let colorButtonTitleHighlighted			= Colors.lightGray
	let colorButtonTitleFeaturedHighlighted = Colors.lightGray
	let colorButtonBorder					= Colors.gray50pcntColor
	let colorButtonBorderFeatured			= Colors.accentColor
	let colorButtonFill						= Colors.clear
	let colorButtonFillFeatured				= Colors.accentColor
	
	let fontText			= UIFont(name: "HelveticaNeue-Light", size: 18)!
	let fontTextDisplay		= UIFont(name: "HelveticaNeue-Light", size: 18)!
	let fontTitle			= UIFont(name: "HelveticaNeue-Thin", size: 36)!
	let fontBanner			= UIFont(name: "HelveticaNeue-Thin", size: 48)!
	let fontComment			= UIFont(name: "HelveticaNeue-Light", size: 16)!
	let fontButtonTitle		= UIFont(name: "HelveticaNeue", size: 16)!
	let fontLinkText		= UIFont(name: "HelveticaNeue", size: 18)!
	
	let dimenButtonCornerRadius = 4
	let dimenButtonBorderWidth = CGFloat(0.5)
	let dimenRuleThickness = CGFloat(1.0)
}

public struct Colors {
	
	static let gray95pcntColor: UIColor = UIColor(red: CGFloat(0.95), green: CGFloat(0.95), blue: CGFloat(0.95), alpha: CGFloat(1))
	static let gray90pcntColor: UIColor = UIColor(red: CGFloat(0.9), green: CGFloat(0.9), blue: CGFloat(0.9), alpha: CGFloat(1))
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
	static let darkGray: UIColor = gray33pcntColor
	static let white: UIColor = UIColor.whiteColor()
	static let black: UIColor = UIColor.blackColor()
	static let clear: UIColor = UIColor.clearColor()
	
	static let brandColor = UIColor(hexString: "#fa6900ff")
	static let brandColorLight = UIColor(red: CGFloat(1), green: CGFloat(0.718), blue: CGFloat(0.302), alpha: CGFloat(1))
	static let accentColor = UIColor(hexString: "#69d2e7ff")
	static let accentColorLight = UIColor(hexString: "#a7dbdbff")
	static let accentColorDark = UIColor(hexString: "#3d99b1ff")
	static let fillColor = UIColor(hexString: "#e0e4ccff")
	static let fillColorLight = UIColor(hexString: "#e9f0cfff")
	
    static let accentColorOld: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0.75), blue: CGFloat(1), alpha: CGFloat(1))
	static let brandColorOld: UIColor = UIColor(red: CGFloat(1), green: CGFloat(0.55), blue: CGFloat(0), alpha: CGFloat(1))
    static let brandColorLightOld: UIColor = UIColor(red: CGFloat(1), green: CGFloat(0.718), blue: CGFloat(0.302), alpha: CGFloat(1))
    static let brandColorDark: UIColor = UIColor(red: CGFloat(0.93), green: CGFloat(0.42), blue: CGFloat(0), alpha: CGFloat(1))
	
    static let windowColor: UIColor = gray90pcntColor
    static let hintColor: UIColor = gray80pcntColor
	static let secondaryText: UIColor = lightGray
	static let separatorColor: UIColor = gray90pcntColor
	
	static let actionOnColor = brandColor
	static let actionOffColor = opacity90pcntWhite
	
	static let facebookColor = UIColor(hexString: "#3B5998ff")
	static let googleColor = UIColor(hexString: "#DD4B39ff")
}
